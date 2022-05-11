class App < Roda
  class AuthorizationError < StandardError; end

  HEADERS = {"Content-Type" => "application/json"}.freeze

  plugin :request_headers
  plugin :json, serializer: proc { |obj| Oj.dump(obj, mode: :compat) }
  plugin :json_parser, parser: proc { |str| Oj.load(str) }
  plugin :error_handler do |error|
    case error
    when Validation::Error
      request.halt [422, HEADERS, [{message: error.message}.to_json]]
    when Authenticate::Error
      request.halt [401, HEADERS, [{message: error.message}.to_json]]
    when App::AuthorizationError
      request.halt [403, HEADERS, [{message: error.message}.to_json]]
    when Sequel::NoMatchingRow
      request.halt [404, HEADERS, [{message: error.message}.to_json]]
    else
      raise error
    end
  end

  route do |request|
    #
    # Creates new task and assigns it to random worker account
    # Returns task info
    #
    # curl -i -H "pid: 8335" -H "token: 8330" -X POST http://127.0.0.1:9293/tasks/create -H 'Content-Type: application/json' -d '{"title":"Task 1"}'
    #
    request.post "tasks/create" do
      Authenticate.call(request)

      attrs = Validation.call(request.POST, CreateTaskForm)
      account = Account.rand_workers.first

      task = DB.transaction do
        Task.create(
          public_id: SecureRandom.uuid,
          title: attrs[:title],
          description: attrs[:description]
        ).tap do |task|
          AccountsTask.create(task_id: task.id, account_id: account.id, is_completed: false)
        end
      end

      task_created_payload = Serializers::EventTaskCreated.call(task)
      PublishEvent.call("task.created", task_created_payload)

      task_assigned_payload = Serializers::EventTaskAssigned.call(task, account)
      PublishEvent.call("task.assigned", task_assigned_payload)

      task_payload = Serializers::Task.call(task)
      request.halt [201, HEADERS, [task_payload]]
    end

    #
    # Assigns random workers to all uncompleted tasks
    # Returns nothing
    # Sends events about each assignment
    #
    # curl -i -H "pid: 1425" -H "token: 8097" -X POST http://127.0.0.1:9293/tasks/shuffle
    #
    request.post "tasks/shuffle" do
      current_account = Authenticate.call(request)
      raise App::AuthorizationError, "Only admins can shuffle tasks" unless current_account.admin?

      Task.uncompleted.order(Sequel.lit("tasks.id")).each_page(100) do |tasks|
        tasks.each do |task|
          account = Account.rand_worker
          account_task =
            DB.transaction do
              task.lock!
              account_task = task.accounts_task
              account_task.update(account_id: account.id) unless account_task.completed?
              account_task
            end

          next if account_task.completed?

          task_assigned_payload = Serializers::EventTaskAssigned.call(task, account)
          PublishEvent.call("task.assigned", task_assigned_payload)
        end
      end

      payload = {message: "Tasks were shuffled"}.to_json
      request.halt [201, HEADERS, [payload]]
    end

    #
    # List all uncompleted tasks of current account
    #
    # curl -i -H "pid: 8335" -H "token: 8330" http://127.0.0.1:9293/tasks
    #
    request.get "tasks" do
      account = Authenticate.call(request)
      tasks = account.uncompleted_tasks
      payload = Serializers::Tasks.call(tasks)

      request.halt [201, HEADERS, [payload]]
    end

    #
    # Complete Task
    # Returns nothing
    # Sends 'task.completed' event
    #
    # curl -i -X POST http://127.0.0.1:9293/tasks/complete -H 'Content-Type: application/json' -d '{"task_id":1}'
    #
    request.post "tasks/complete" do
      attrs = Validation.call(request.POST, CompleteTaskForm)
      account = Authenticate.call(request)
      task = Task.with_pk!(attrs[:task_id])

      was_completed =
        DB.transaction do
          task.lock!
          account_task = AccountsTask.find!(account_id: account.id, task_id: task.id)
          account_task.update(is_completed: true) if account_task.uncompleted?
        end

      if was_completed
        task_completed_payload = Serializers::EventTaskCompleted.call(task, account)
        PublishEvent.call("task.completed", task_completed_payload)
      end

      payload = {message: "Task was completed"}.to_json
      request.halt [201, HEADERS, [payload]]
    end
  end
end
