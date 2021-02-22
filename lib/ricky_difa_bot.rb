class RickyDifaBot

  KEYBOARDS = [
    ['/daftar_belanja'],
    ['Accounts'],
    ['Remaining Budget'],
    ['/lihat_list']
  ]

  def self.start
    Telegram::Bot::Client.run($telegram_bot_token) do |bot|
      bot.listen do |message|
        RickyDifaBot::InputProcessor.perform_async(message, bot)
      end
    end
  rescue StandardError => e
    log(e.inspect)
    retry
  end

  def self.log(message)
    RickyDifaBot::RickyDifaLog.perform_async(message)
  end

  def self.reload!
    Rake::Task['ricky_difa_bot:reload'].execute
  end
end
