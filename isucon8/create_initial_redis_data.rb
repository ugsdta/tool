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

start_time = Time.now.to_i

system("sudo rm /var/lib/redis/appendonly.aof")
system("sudo systemctl restart redis")

redis_connection = Redis.new(:path => "/var/run/redis/redis.sock")

db.query("DELETE FROM relations WHERE id > 500000")
db.query("DELETE FROM footprints WHERE id > 500000")
db.query("DELETE FROM entries WHERE id > 500000")
db.query("DELETE FROM comments WHERE id > 1500000")

# entry_comments_count
redis_ec_count = Redis::Namespace.new(:entry_comments_count, :redis => redis_connection)
entries_query = <<SQL
select id from entries
SQL
Redis.current = redis_ec_count
db.query(entries_query).each do |entry|
  puts "entry_comments_count:entry_id = #{entry[:id]}"
  db.xquery('SELECT COUNT(id) as c FROM comments WHERE entry_id = ?', entry[:id]).each do |c|
    redis_ec_count = Redis::Counter.new(entry[:id])
    redis_ec_count.value = c[:c]
  end
end

# relations
redis_relations = Redis::Namespace.new(:relations, :redis => redis_connection)
query = <<SQL
SELECT *
FROM relations
SQL
Redis.current = redis_relations
db.xquery(query).each do |rl|
  id = rl[:id]
  one = rl[:one]
  another = rl[:another]
  created_at = rl[:created_at]
  puts "relations:#{id}"
  rl_sorted_set = Redis::SortedSet.new(one)
  rl_sorted_set[another] = created_at.to_i
end

# function
def is_friend?(redis, one_id, another_id)
  Redis.current = redis
  redis_rl_ss = Redis::SortedSet.new(one_id)
  redis_rl_ss.score(another_id) ? true : false
end
def permitted?(redis, one_id, another_id)
  another_id == one_id || is_friend?(redis, one_id, another_id)
end

# friends_comments
redis_friends_comments = Redis::Namespace.new(:friends_comments, :redis => redis_connection)
query = <<SQL
SELECT *
FROM users
SQL
comments_query = <<SQL
SELECT * FROM comments ORDER BY created_at DESC LIMIT 1000
SQL
db.query(query).each do |user|
  puts "friends_comments:user_id = #{user[:id]}"
  cnt = 0
  db.query(comments_query).each do |c|
    next unless is_friend?(redis_relations, user[:id], c[:user_id])
    entry = db.xquery('SELECT * FROM entries WHERE id = ?', c[:entry_id]).first
    entry[:is_private] = (entry[:private] == 1)
    next if entry[:is_private] && !permitted?(redis_relations, user[:id], entry[:user_id])
    id = c[:id]
    created_at = c[:created_at]
    Redis.current = redis_friends_comments
    redis_fc_ss = Redis::SortedSet.new(user[:id])
    redis_fc_ss[id] = created_at.to_i
    cnt += 1
    break if cnt >= 10 
  end
end
    
# friends_entries
redis_friends_entries = Redis::Namespace.new(:friends_entries, :redis => redis_connection)
query = <<SQL
SELECT *
FROM users
SQL
entries_query = <<SQL
SELECT * FROM entries ORDER BY created_at DESC LIMIT 1000
SQL
db.query(query).each do |user|
  puts "friends_entries:user_id = #{user[:id]}"
  cnt = 0
  db.query(entries_query).each do |e|
    next unless is_friend?(redis_relations, user[:id], e[:user_id])
    id = e[:id]
    created_at = e[:created_at]
    Redis.current = redis_friends_entries
    redis_fe_ss = Redis::SortedSet.new(user[:id])
    redis_fe_ss[id] = created_at.to_i
    cnt += 1
    break if cnt >= 10 
  end
end

# comments_for_me
redis_comments_for_me = Redis::Namespace.new(:comments_for_me, :redis => redis_connection)
query = <<SQL
SELECT *
FROM users
SQL
comments_for_me_query = <<SQL
SELECT c.id AS id, c.entry_id AS entry_id, c.user_id AS user_id, c.comment AS comment, c.created_at AS created_at
FROM comments c
JOIN entries e ON c.entry_id = e.id
WHERE e.user_id = ?
ORDER BY c.created_at DESC
LIMIT 10
SQL
Redis.current = redis_comments_for_me
db.query(query).each do |user|
  puts "comments_for_me:user_id = #{user[:id]}"
  db.xquery(comments_for_me_query, user[:id]).each do |c|
    id = c[:id]
    created_at = c[:created_at]
    redis_cfm_ss = Redis::SortedSet.new(user[:id])
    redis_cfm_ss[id] = created_at.to_i
  end
end

# footpritns
redis_footprints = Redis::Namespace.new(:footprints, :redis => redis_connection)

query = <<SQL
SELECT *
FROM footprints
SQL

Redis.current = redis_footprints
db.xquery(query).each do |fp|
  id = fp[:id]
  user_id = fp[:user_id]
  owner_id = fp[:owner_id]
  created_at = fp[:created_at]
  puts "footprints:#{id}"
  created_date = created_at.to_s.split(" ")[0]
  fp_sorted_set = Redis::SortedSet.new(user_id)
  fp_sorted_set["#{owner_id}:#{created_date}"] = created_at.to_i
end


# create initial data file
system("sudo rsync -az /var/lib/redis/appendonly.aof /home/isucon/data/")

end_time = Time.now.to_i

pp "#{end_time - start_time} sec"
