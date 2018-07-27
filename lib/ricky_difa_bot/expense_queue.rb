class RickyDifaBot::ExpenseQueue
  KEY = 'expense_queue_hash'

  KEYBOARDS = [
    [
      ['T65R', 'T65T'],
      ['T7R', 'T7T'],
      ['T95R', 'T95T'],
      ['T16R', 'T16T'],
      ['T165R', 'T165T']
    ],
    [
      ['Busway Flazz', 'KAI Flazz'],
      ['Busway Tapcash', 'KAI Tapcash']
    ]
  ]

  def self.add(item, date)
    while $redis.hget(KEY, date).present?
      date += 1
    end
    item = "#{Time.at(date).strftime("%Y-%m-%d %H:%M")}\n#{item}"
    $redis.hset(KEY, date, item)
  end
end
