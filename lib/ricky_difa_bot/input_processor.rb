class RickyDifaBot::InputProcessor
  include SuckerPunch::Job
  workers 5

  attr_accessor :bot

  def perform(message, bot)
    @bot = bot
    # enables the bot only for us
    return unless message.chat.id.in?([$ricky_difa_group, $ricky, $difa])
    # ignores edited messages
    return if message.edit_date

    # ignores other type of messages
    return unless message.text

    RickyDifaBot.log("INCOMING #{message.inspect}")

    text = message.text.sub("@#{$bot_username}", '')

    if in_ricky_difa_group?(message)
      if text =~ /^\/reload$/i
        RickyDifaBot.reload!
        reply(message, 'Reloaded!')
      elsif text =~ /^\/daftar_belanja$/i
        reply(message, RickyDifaBot::GroceryList.instance.list)
      elsif text =~ /^\/beli (.+) (\w+)$/i
        begin
          item = $1
          type =
            case $2
            when /cepat/i
              :short
            when /ntaran/i
              :mid
            when /pankapan/i
              :long
            end
          RickyDifaBot::GroceryList.instance.send("add_#{type}", item)
          reply(message, 'Berhasil ditambahkan ke /daftar_belanja!')
        rescue
          reply(message, 'Gagal! Salah format?')
        end
      elsif text =~ /^\/hapus (\d+) (\w+)$/i
        begin
          index = $1.to_i - 1
          return unless index >= 0
          type =
            case $2
            when /cepat/i
              :short
            when /ntaran/i
              :mid
            when /pankapan/i
              :long
            end
          removed = RickyDifaBot::GroceryList.instance.send("remove_#{type}", index)
          reply(message, "Berhasil menghapus #{removed} dari /daftar_belanja!") if removed
        rescue
          reply(message, 'Gagal! Salah format?')
        end
      end
    end
  end

  private

  def in_private?(message)
    message.chat.type == 'private'
  end

  def in_ricky_difa_group?(message)
    message.chat.id == $ricky_difa_group
  end

  def reply(message, text)
    send(chat_id: message.chat.id, text: text, reply_to_message_id: message.message_id)
  end

  def send(options = {})
    RickyDifaBot::MessageSender.perform_async(@bot, options)
  end
end
