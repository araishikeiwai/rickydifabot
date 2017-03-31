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

    if text =~ /^\/reload$/i && message.from.username == 'araishikeiwai'
      RickyDifaBot.reload!
      reply(message, 'Reloaded!')
    end

    if in_ricky_difa_group?(message)
      if text =~ /^\/daftar_belanja$/i
        reply(message, RickyDifaBot::GroceryList.instance.list)
      elsif text =~ /^\/beli((?:.+))+(\b\w+\b)$/im
        begin
          items = $1.split("\n").map(&:strip).select(&:present?)
          type =
            case $2
            when /cepat/i
              :short
            when /ntaran/i
              :mid
            when /pankapan/i
              :long
            end
          RickyDifaBot::GroceryList.instance.send("add_#{type}", items)
          reply(message, "Berhasil ditambahkan ke /daftar_belanja! Daftar belanja terbaru:\n\n#{RickyDifaBot::GroceryList.instance.list}")
        rescue
          reply(message, 'Gagal! Salah format?')
        end
      elsif text =~ /^\/hapus ((?:\d+ ?)+)$/i
        begin
          indices = $1.split.map{ |i| i.to_i - 1 }
          return unless indices.all?{ |i| i >= 0 }
          removed = RickyDifaBot::GroceryList.instance.remove(indices)
          reply(message, "Berhasil menghapus\n#{removed.join("\n")}\ndari daftar belanja! Daftar belanja terbaru:\n\n#{RickyDifaBot::GroceryList.instance.list}") if removed.present?
        rescue
          reply(message, 'Gagal! Salah format?')
        end
      elsif text =~ /^\/pindah ((?:\d+ ?)+) (\w+)$/i
        begin
          indices = $1.split.map{ |i| i.to_i - 1 }
          type =
            case $2
            when /cepat/i
              :short
            when /ntaran/i
              :mid
            when /pankapan/i
              :long
            end
          return unless indices.all?{ |i| i >= 0 }
          moved = RickyDifaBot::GroceryList.instance.move(indices, type)
          reply(message, "Berhasil memindahkan\n#{moved.join("\n")}\nke daftar #{type}-term! Daftar belanja terbaru:\n\n#{RickyDifaBot::GroceryList.instance.list}") if moved.present?
        rescue
          reply(message, 'Gagal! Salah format?')
        end
      elsif text =~ /#exq/i
        date = message.date
        if message.reply_to_message
          text = message.reply_to_message&.text
          date = message.reply_to_message&.date
        end
        subbed = text.gsub(/ *#exq */, '')
        RickyDifaBot::ExpenseQueue.add(subbed, date)
        reply(message, "Berhasil menambahkan #{subbed} ke daftar pending")
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
