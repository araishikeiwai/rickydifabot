class RickyDifaBot::ExpenseQueue
  KEY = 'expense_queue'

  def self.list
    $redis.lrange(KEY, 0, -1)
  end

  def self.add(item)
    $redis.rpush(KEY, "#{DateTime.now.strftime("%Y-%m-%d %H:%M")}\n#{item}")
  end

  def self.clear
    $redis.del(KEY)
  end
end
