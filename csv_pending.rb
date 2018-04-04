load 'Rakefile'
Rake::Task['ricky_difa_bot:reload'].execute
require 'csv'

CSV.foreach('pending.csv') do |row|
  next if row[0] == 'Y'
  dt = DateTime.new(row[0].to_i, row[1].to_i, row[2].to_i, row[3].to_i, row[4].to_i, 0, Rational(7, 24))
  text = []
  text << row[6]
  text << "accx #{row[5]}"
  text << "catx #{row[7]}"
  text << "ownx #{row[9]}"
  text << row[8]
  text << "totx #{row[10]}"

  RickyDifaBot::ExpenseQueue.add(text.join("\n"), dt.to_i)
end
