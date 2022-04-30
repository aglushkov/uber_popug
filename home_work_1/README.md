# Home work week 1

## Data Model
[Image](/home_work_1/data_model.png)
![Image](/home_work_1/data_model.png?raw=true)

## Domain Model
[Image](/home_work_1/domain_model.png)
![Image](/home_work_1/domain_model.png?raw=true)

## Services
- Auth
- Tasks
- Accounting
- Analytics

All connections are asynchronous

## Common Data
- User - in all services
- Task - in Tasks and Accounting
- BalanceLog - in Accounting and Analytics

## Business Events
- Task assigned - produced by "Tasks", consumed by "Accounting"
- Task completed - produced by "Tasks", consumed by "Accounting"

## CUD Events
- User Created/Updated/Deleted - produced by "Auth", consumed by all services
- Task Created - produced by "Tasks", consumed by "Accounting"
- BalanceLog Created - produced by "Accounting", consumed by "Analytics"

## Requirements: find Actor, Command, Data, Event

Tasks:
| Requirement | Actor | Command | Data | Event |
| ----------- | ----- | ------- | ---- | ----- |
| Create Task | User | Create Task | Task, User | Task Assigned |
| Shuffle Tasks | User | Shuffle Tasks | UserTask, User | Task Assigned * N tasks |
| Complete Task | User | Complete Task | Task, UserTask | Task Completed |

Accounting
| Requirement | Actor | Command | Data | Event |
| ----------- | ----- | ------- | ---- | ----- |
| Decrement balance after assigning task | event "Task Assigned" | RemoveMoney | TaskPrice, UserTaskLog, BalanceLog, Balance | BalanceLog Created (CUD) |
| Increment balance after completing task | event "Task Completed" | AddMoney | TaskPrice, UserTaskLog, BalanceLog, Balance | BalanceLog Created (CUD) |
| Pay and Notify Users Daily | Cron | PayUser | BalanceLog, Balance | BalanceLog Created (CUD) |
