class RickyDifaBot::RickyDifaLog
  include SuckerPunch::Job
  workers 5

  def perform(message)
    $logger.info do
      message.gsub("\n", ' ::: ')
    end
  end
end
