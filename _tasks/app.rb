class TasksApp < Roda
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
    when TasksApp::AuthorizationError
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

      task = Tasks::Create.new.call(attrs) # actions/tasks/create.rb

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

      Tasks::Shuffle.new.call # actions/tasks/shuffle.rb

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

      Tasks::Complete.new.call(task, by_account: account) # actions/tasks/complete.rb

      payload = {message: "Task was completed"}.to_json
      request.halt [201, HEADERS, [payload]]
    end

    #
    # Complete Random Task (for testing purposes)
    # Returns nothing
    # Sends 'task.completed' event
    #
    # curl -i -X POST http://127.0.0.1:9293/tasks/complete_random -H 'Content-Type: application/json'
    #
    request.post "tasks/complete_random" do
      task = Task.uncompleted.order(Sequel.lit("RANDOM()")).first || raise(Sequel::NoMatchingRow)

      Tasks::Complete.new.call(task) # actions/tasks/complete.rb

      payload = {message: "Task was completed"}.to_json
      request.halt [201, HEADERS, [payload]]
    end
  end
end
