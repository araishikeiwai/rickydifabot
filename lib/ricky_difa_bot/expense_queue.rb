class RickyDifaBot::ExpenseQueue
  KEY = 'expense_queue_hash'

  KEYBOARDS = [
    [
      ['T65R', 'T65T'],
      ['T95R', 'T95T'],
      ['T16R', 'T16T']
    ],
    [
      ['Busway Flazz'],
      ['Busway Tapcash']
    ]
  ]

  def self.add(item, date)
    item = "#{Time.at(date).strftime("%Y-%m-%d %H:%M")}\n#{item}"
    $redis.hset(KEY, date, item)
  end
end
