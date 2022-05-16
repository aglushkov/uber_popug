Sequel.migration do
  change do
    add_column :tasks, :jira_id, String
  end
end
