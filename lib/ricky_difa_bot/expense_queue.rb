class RickyDifaBot::ExpenseQueue
  KEY = 'expense_queue'

  def self.list
    $redis.lrange(KEY, 0, -1)
  end

  def self.add(item, date)
    time = Time.at(date)
    $redis.rpush(KEY, "#{time.strftime("%Y-%m-%d %H:%M")}\n#{item}")
  end

  def self.clear
    $redis.del(KEY)
  end
end
