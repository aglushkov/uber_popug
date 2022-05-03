### Home Work 0

- [Original schema](https://lucid.app/lucidchart/5aadd895-4b1e-49af-a9c8-5a34eedc5292/edit?invitationId=inv_02a5e0e2-e9fe-4c8b-9960-24af7633693c)
- [Image schema](/home_work_0/image0.png)

### Home Work Week 1
- [Readme](/home_work_1/README.md)

### Home Work Week 2

#### Application

1. Run RabbitMQ
```
sudo docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3.9-management
```

2. Run services
```
  cd _authn
  rackup -p 9292

  cd _tasks
  rackup -p 9293
```

3. Create some accounts
```
 cd _authn
 ruby seed.rb
```

### Requests

1. Register account with 'worker' role

  Params: email, password, role, name
  ```
  curl -s -X POST http://127.0.0.1:9292/accounts/register -H 'Content-Type: application/json' -d '{"email":"bruce@example.com","password":"password", "role":"worker", "name":"Name 1"}' | jq
  ```

  Response example:
  ```json
  {
    "account": {
      "public_id": "8757",
      "name": "Name 1",
      "email": "bruce@example.com",
      "role": "worker"
    }
  }
  ```

2. Register admin account
  Params: email, password, role, name
  ```
  curl -s -X POST http://127.0.0.1:9292/accounts/register -H 'Content-Type: application/json' -d '{"email":"admin@example.com","password":"password", "role":"admin", "name":"Admin 1"}' | jq
  ```
  Response example:
  ```json
  {
    "account": {
      "public_id": "8729",
      "name": "Admin 1",
      "email": "admin@example.com",
      "role": "admin"
    }
  }
  ```

3. Login.
  Params: email, password
  ```
  curl -s -X POST http://127.0.0.1:9292/accounts/login -H 'Content-Type: application/json' -d '{"email":"email_1@example.com","password":"password"}' | jq
  ```

  Response example:
  ```json
  {
    "pid": "8335",
    "token": "7512"
  }
  ```

4. Authenticate account
  Params: public_id, session_token
  ```
  curl -s -X POST http://127.0.0.1:9292/accounts/authenticate -H 'Content-Type: application/json' -d '{"public_id":"8335","session_token":"8330"}' | jq
  ```
  Response_example:
  ```json
  {
    "account": {
      "public_id": "8335",
      "name": "name_1",
      "email": "email_1@example.com",
      "role": "worker"
    }
  }
  ```

5. List own tasks
  Headers: pid, token (received from `/accounts/login`)
  ```
  curl -s -H "pid: 8335" -H "token: 8330" http://127.0.0.1:9293/tasks | jq
  ```
  Response example:
  ```json
  {
    "tasks": [
      {
        "id": 14,
        "public_id": "6246",
        "title": "Task 1",
        "description": null
      }
    ]
  }
  ```

6. Create task
  Headers: pid, token (received from `/accounts/login`)
  Params: title (required), description (optional)
  ```
  curl -s -H "pid: 8335" -H "token: 8330" -X POST http://127.0.0.1:9293/tasks/create -H 'Content-Type: application/json' -d '{"title":"Task 1", "description":"Description 1"}' | jq
  ```
  Response example:
  ```json
  {
    "task": {
      "id": 109,
      "public_id": "7608",
      "title": "Task 1",
      "description": "Description 1"
    }
  }
  ```

7. Complete task
  Headers: pid, token (received from `/accounts/login`)
  Params: task_id
  ```
  curl -s -H "pid: 8335" -H "token: 1781" -X POST http://127.0.0.1:9293/tasks/complete -H 'Content-Type: application/json' -d '{"task_id":1}' | jq
  ```
  Response example:
  ```json
  {
    "message": "Task was completed"
  }
  ```

8. Shuffle tasks
  Headers: pid, token (received from `/accounts/login`)
  ```
  curl -s -H "pid: 1425" -H "token: 8097" -X POST http://127.0.0.1:9293/tasks/shuffle | jq
  ```
   Response example:
  ```json
  {
    "message": "Tasks were shuffled"
  }
  ```
