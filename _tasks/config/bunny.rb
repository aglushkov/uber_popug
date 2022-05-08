BUNNY_CONNECTION = Bunny.new
BUNNY_CONNECTION.start

#
# Subscriptions
#
channel = BUNNY_CONNECTION.create_channel
exchange = channel.topic("app", auto_delete: true)

channel.queue("").bind(exchange, routing_key: "account.created").subscribe do |_delivery_info, _metadata, payload|
  data = Oj.load(payload).fetch("account")

  Account.find_or_create(public_id: data.fetch("public_id")) do |account|
    account.name = data.fetch("name")
    account.role = data.fetch("role")
  end
end
