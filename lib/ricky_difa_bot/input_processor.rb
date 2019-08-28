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
      if text =~ /^\/daftar[_ ]belanja$/i
        reply(message, RickyDifaBot::GroceryList.instance.list)
      elsif text =~ /^\/lihat[_ ]list/
        res = ['Daftar To-Do List']
        res << ''
        RickyDifaBot::ToDoList.order_by(id_int: :asc).each do |list|
          res << "(##{list.id_int}) #{list.name}"
          res << "#{list.sublist_count} kategori, #{list.contents_count} entri"
          res << "Lihat di /lihat_#{list.id_int}"
          res << ''
        end
        reply(message, res.join("\n"))
      elsif text =~ /^\/lihat[_ ](\d+)/
        list = RickyDifaBot::ToDoList.find_by(id_int: $1.to_i)
        return unless list
        reply(message, list.to_s)
      elsif text =~ /^\/buat[_ ]list (.+)/
        name = $1
        status =
          if RickyDifaBot::ToDoList.create(name: name)
            'Berhasil'
          else
            'Gagal'
          end
        reply(message, "#{status} menambahkan #{name} sebagai To-Do List baru!\n\n/lihat_list")
      elsif text =~ /^\/hapus[_ ]list (\d+)/
        list = RickyDifaBot::ToDoList.find_by(id_int: $1.to_i)
        return unless list
        name = list.name
        status =
          if list.destroy
            'Berhasil'
          else
            'Gagal'
          end
        reply(message, "#{status} menghapus #{name} dari daftar To-Do List!\n\n/lihat_list")
      elsif text =~ /^\/tambah[_ ]kategori (\d+) (.+)/
        list = RickyDifaBot::ToDoList.find_by(id_int: $1.to_i)
        return unless list
        sublist = $2
        if list.add_sublist(sublist)
          reply(message, "Berhasil menambahkan #{sublist} sebagai kategori baru!\n\n#{list}")
        else
          reply(message, "Gagal menambahkan #{sublist} sebagai kategori baru!")
        end
      elsif text =~ /^\/hapus[_ ]kategori (\d+) (\d+)/
        list = RickyDifaBot::ToDoList.find_by(id_int: $1.to_i)
        return unless list
        sublist = nil
        status =
          if sublist = list.remove_sublist($2.to_i)
            'Berhasil'
          else
            'Gagal'
          end
        reply(message, "#{status} menghapus #{sublist} dari To-Do List ini!\n\n#{list}")
      elsif text =~ /^\/done (\d+) ((?:\d+\.\d+ ?)+)/
        id_int = $1.to_i
        indices = $2.split
        list = RickyDifaBot::ToDoList.find_by(id_int: id_int)
        return unless list
        removed = []
        indices.group_by do |idx|
          idx.split('.').first.to_i
        end.each do |title_idx, contents|
          content_indices = contents.map { |c| c.split('.').last.to_i }
          if tmp = list.remove(title_idx, content_indices)
            removed << tmp.join(', ')
          end
        end
        reply(message, "Berhasil menghapus\n#{removed.join("\n")}\ndari to do list ini!\n\n#{list}")
      elsif text =~ /^\/do((?:.+))+\b(\d+) (\d+)\b/im
        items = $1.split("\n").map(&:strip).select(&:present?)
        id_int = $2&.to_i
        sublist_idx = $3&.to_i
        return unless id_int && sublist_idx
        list = RickyDifaBot::ToDoList.find_by(id_int: id_int)
        return unless list
        if list.add([items], sublist_idx)
          reply(message, "Berhasil ditambahkan!\n\n#{list}")
        end
      elsif text =~ /^\/beli((?:.+))+(\b\w+\b)$/im
        begin
          items = $1.split("\n").map(&:strip).select(&:present?)
          type =
            case $2
            when /cepat/i
              :short
            when /soon/i
              :shmid
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
            when /soon/i
              :shmid
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
      elsif text =~ /^\/keyboard$/
        keyboard =
          case message.from.id
          when $ricky
            Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: RickyDifaBot::ExpenseQueue::KEYBOARDS[0] + RickyDifaBot::Timeline::KEYBOARDS.keys.map { |command| [command] }, resize_keyboard: true, one_time_keyboard: true, selective: true)
          when $difa
            Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: RickyDifaBot::ExpenseQueue::KEYBOARDS[1] + RickyDifaBot::ExpenseQueue::KEYBOARDS[0].map { |kb| [kb[1]] }, resize_keyboard: true, one_time_keyboard: true, selective: true)
          end
        reply(message, 'Ya?', reply_markup: keyboard)
      elsif text.in?(RickyDifaBot::Timeline::KEYBOARDS.keys) && message.from.id == $ricky
        command = RickyDifaBot::Timeline::KEYBOARDS[text]
        RickyDifaBot::Timeline.send("#{command}!", DateTime.now)
        reply(message, 'OK~')
      elsif text.in?(RickyDifaBot::ExpenseQueue::KEYBOARDS.flatten)
        date = message.date
        RickyDifaBot::ExpenseQueue.add(text, date)
        reply(message, 'OK~')
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

  def reply(message, text, opts = {})
    send(opts.reverse_merge(chat_id: message.chat.id, text: text, reply_to_message_id: message.message_id))
  end

  def send(options = {})
    RickyDifaBot::MessageSender.perform_async(@bot, options)
  end
end
