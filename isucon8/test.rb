# coding: utf-8
require 'mysql2'
require 'mysql2-cs-bind'
require 'pp'
require 'redis'
require 'redis/namespace'
require 'redis-objects'
require 'json'

db = Mysql2::Client.new(
  host: '127.0.0.1',
  port: '3306',
  username: 'isucon',
  password: 'isucon',
  database: 'isucon5q',
  reconnect: true,
)
db.query_options.merge!(symbolize_keys: true)

redis_connection = Redis.new(:path => "/var/run/redis/redis.sock")
redis_ts = Redis::Namespace.new(:testspace, :redis => redis_connection)

Redis.current = redis_ts

# query = 'SELECT * FROM users'
# count = 1
# client.query(query).each do |user|
#   puts "count = #{count} user_id = #{user[:id]}"
#   redis_user = Redis::HashKey.new(user[:id])
#   redis_user.bulk_set('account_name' => user[:account_name], 'nick_name' => user[:nick_name], 'email' => user[:email], 'passhash' => user[:passhash])
#   count += 1
# end

# redis_ss = Redis::SortedSet.new("testkey")
# redis_ss[1] = 10
# redis_ss[2] = 20
# redis_ss[3] = 30
# pp redis_ss.members
# #pp redis_ss["testmember4"]
# #pp redis_ss.score("testmember4")
# #pp redis_ss.rank("testmember4")
# hash = {}
# for mem in redis_ss.members
#   hash[mem] = 1
# end
# pp hash
# pp hash["1"]

#query = 'insert into comments (entry_id, user_id, comment) values (?, ?, ?)'
#res = client.xquery(query, 1, 1, 'testcomment')
#pp client.last_id

#array = ["3", "1", "2"]
# array = [3, 1, 2]
# query = 'select * from comments where id in (?) order by field (id, ?)'
# db.xquery(query, array, array).each do |c|
#   pp c[:id]
# end
# 
# pp 1 == "1"

# redis_ss = Redis::SortedSet.new("1")
# redis_ss[1] = 10
# redis_ss[2] = 20
# redis_ss = Redis::SortedSet.new(1)
# redis_ss[1] = nil
# pp redis_ss.members(:with_scores => true)
#pp redis_ss.score("1")

# comments_query = <<SQL
# SELECT * FROM comments ORDER BY created_at DESC LIMIT 1000
# SQL
#   cnt = 0
#   db.query(comments_query).each do |c|
#     #next unless is_friend?(redis_relations, user[:id], c[:user_id])
#     #entry = db.xquery('SELECT * FROM entries WHERE id = ?', c[:entry_id]).first
#     #entry[:is_private] = (entry[:private] == 1)
#     #next if entry[:is_private] && !permitted?(redis_relations, user[:id], entry[:user_id])
#     id = c[:id]
#     created_at = c[:created_at]
#     pp id
#     pp created_at.to_i
#     redis_fc_ss = Redis::SortedSet.new(111)
#     redis_fc_ss[id] = created_at.to_i
#     cnt += 1
#     break if cnt >= 10 
#   end

#       user_comments_query = <<SQL
# select id, entry_id, created_at
# from comments
# where user_id = ?
# order by created_at desc
# limit 50
# SQL
#       entries_query = <<SQL
# select id, user_id, private
# from entries
# where id in (?)
# SQL
#       comments = db.xquery(user_comments_query, 3657)
#       entry_ids = comments.map{|c| c[:entry_id]}
#       #pp entry_ids
#       entries = {}
#       db.xquery(entries_query, entry_ids).each do |e|
#         entries[e[:id]] = e  
#       end
#       pp entries
#       # cnt = 0
#       # comments.each do |comment|
#       #   entry_id = comment[:entry_id]
#       #   entry_user_id = entries[entry_id.to_s][:user_id]

entries_query = <<SQL
select id from entries
SQL
puts "entry_comments_count"
db.query(entries_query).each do |entry|
  puts "entry_id:#{entry[:id]}"
  db.xquery('SELECT COUNT(id) as c FROM comments WHERE entry_id = ?', entry[:id]).each do |c|
    redis_ec_count = Redis::Counter.new(entry[:id])
    redis_ec_count.value = c[:c]
  end
end







