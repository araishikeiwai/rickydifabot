require 'rake'
require 'redis'
require 'mongoid'
require 'mongoid-locker'
require 'telegram/bot'
require 'sucker_punch'
require 'active_support/all'
require 'cachy'

Dir[File.dirname(__FILE__) + '/config/inits/*.rb'].each{ |file| require file }
Dir[File.dirname(__FILE__) + '/lib/ricky_difa_bot.rb'].each{ |file| require file }
Dir[File.dirname(__FILE__) + '/lib/ricky_difa_bot/**/*.rb'].each{ |file| require file }

Mongoid.load!(File.dirname(__FILE__) + '/config/mongoid.yml', :production)

namespace :ricky_difa_bot do
  task :start do
    RickyDifaBot.start
  end
end

task default: 'ricky_difa_bot:start'
