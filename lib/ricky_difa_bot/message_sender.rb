class RickyDifaBot::MessageSender
  include SuckerPunch::Job
  workers 5

  DEFAULT_MESSAGE_OPTIONS = {
    parse_mode: 'HTML'
  }.freeze

  def perform(bot, options)
    options.reverse_merge!(DEFAULT_MESSAGE_OPTIONS)
    return unless options[:chat_id] && options[:text]

    options[:text].scan(/.{1,4000}/m) do |text|
      begin
        options[:text] = text
        RickyDifaBot.log("OUTGOING #{options.inspect}")
        bot.api.send_message(options)
        sleep(0.1)
      rescue Faraday::TimeoutError => e
        RickyDifaBot.log('TIMEOUT')
        sleep(1.3)
        retry
      rescue Telegram::Bot::Exceptions::ResponseError => e
        RickyDifaBot.log(e.inspect)
        if e.message =~ /error_code: .429./
          sleep(3)
        end
        retry unless e.message =~ /error_code: .(400|403|409)./
      end
    end
  end
end
