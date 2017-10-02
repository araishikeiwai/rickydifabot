load 'Rakefile'
Rake::Task['ricky_difa_bot:reload'].execute
puts RickyDifaBot::Timeline.summary
