require 'rake'
require 'redis'
require 'mongoid'
require 'mongoid-locker'
require 'telegram/bot'
require 'sucker_punch'
require 'active_support/all'
require 'cachy'
require 'pry'

def reload!
  Dir[File.dirname(__FILE__) + '/config/inits/*.rb'].each{ |file| load file }
  Dir[File.dirname(__FILE__) + '/lib/ricky_difa_bot.rb'].each{ |file| load file }
  Dir[File.dirname(__FILE__) + '/lib/ricky_difa_bot/**/*.rb'].each{ |file| load file }
end

Mongoid.load!(File.dirname(__FILE__) + '/config/mongoid.yml', :production)

namespace :ricky_difa_bot do
  task :reload do
    reload!
  end

  task start: :reload do
    RickyDifaBot.start
  end
end

task default: 'ricky_difa_bot:start'
