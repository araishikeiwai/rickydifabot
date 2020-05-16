require 'rake'
require 'redis'
require 'mongoid'
require 'mongoid-locker'
require 'telegram/bot'
require 'sucker_punch'
require 'active_support/all'
require 'cachy'
require 'pry'
require 'graphql/client'
require 'graphql/client/http'

def reload!
  Dir[File.dirname(__FILE__) + '/config/inits/*.rb'].each{ |file| load file }

  http = GraphQL::Client::HTTP.new("#{$gql_url}/expense_manager/graphql") do
    def headers(context)
      { "Authorization": $auth_token }
    end
  end
  schema = GraphQL::Client.load_schema(http)

  $gql = GraphQL::Client.new(schema: schema, execute: http)

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
