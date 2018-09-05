require 'mysql2'
require 'mysql2-cs-bind'
require 'pp'

client = Mysql2::Client.new(
  host: '127.0.0.1',
  port: '3306',
  username: 'isucon',
  password: 'isucon',
  database: 'isucon5q',
  reconnect: true,
)
client.query_options.merge!(symbolize_keys: true)

#query = 'SELECT * FROM relations WHERE one = ?'
#relation = client.xquery(query, '3333').first
#pp relation

query = 'SELECT id,user_id FROM entries limit 200000 offset 390000'
count = 390000
client.xquery(query).each do |entry|
  #pp entry
  #break;
  query = 'UPDATE comments SET entry_user_id = ? WHERE entry_id = ?'
  client.xquery(query, entry[:user_id], entry[:id])
  count += 1
  puts count
end
