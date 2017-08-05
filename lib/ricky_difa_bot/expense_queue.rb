class RickyDifaBot::ExpenseQueue
  KEY = 'expense_queue_hash'

  def self.add(item, date)
    item = "#{Time.at(date).strftime("%Y-%m-%d %H:%M")}\n#{item}"
    $redis.hset(KEY, date, item)
  end
end
