class RickyDifaBot::ExpenseQueue
  KEY = 'expense_queue_hash'

  KEYBOARDS = [
    [
      ['T45R', 'T45T'],
      ['T65R', 'T65T'],
      ['T7R', 'T7T'],
      ['T95R', 'T95T'],
      ['T15R', 'T15T'],
      ['T16R', 'T16T'],
      ['T165R', 'T165T'],
      ['T215R', 'T215T'],
      ['T22R', 'T22T'],
    ],
    [
      ['Busway Flazz', 'KAI Flazz'],
      ['Busway E-money', 'KAI E-money'],
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
