class ShardedModel
  include MongoMapper::Document

  key :first_name, String
  key :last_name, String
  shard_key :first_name
end

if ENV.fetch("ENABLE_SHARDING", "0") == "1"
  client = MongoMapper.connection
  database = MongoMapper.database

  # https://www.mongodb.com/docs/manual/reference/command/enableSharding/#mongodb-dbcommand-dbcmd.enableSharding
  client.use(:admin).command(enableSharding: database.name)

  # https://www.mongodb.com/docs/manual/reference/command/shardCollection/#mongodb-dbcommand-dbcmd.shardCollection
  # Note: this command automatically creates the index for the empty collection
  client.use(:admin).command(
    shardCollection: [database.name, ShardedModel.collection.name].join("."),
    key: {
      first_name: "hashed",
    },
  )
end
