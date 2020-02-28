class RickyDifaBot::Timeline
  include Mongoid::Document

  field :date,          type: Date
  field :go,            type: Integer
  field :work_start,    type: Integer
  field :work_finished, type: Integer
  field :home,          type: Integer

  index({ date: 1 }, { background: true, unique: true })

  default_scope -> { order_by(date: :asc) }

  KEYBOARDS = {
    'Commuting' => :go,
    'Arrived at work' => :work_start,
    'Going home' => :work_finished,
    'Arrived at home' => :home
  }

  fields.except('_id').keys.each do |action|
    define_singleton_method("#{action}!") do |time|
      date = time.to_date
      self.find_or_create_by(date: date).update_attributes(action => time.to_i)
    end
  end

  def self.summary
    prints = []
    prints2 = []

    hasht = {
      go: [],
      work_start: [],
      work_finished: [],
      home: []
    }
    hash2 = {
      wd: [],
      gd: [],
      hd: [],
      tc: []
    }

    #prints <<
    #  [
    #    "Date",
    #    fields.except('_id', 'date').keys.map do |action|
    #      "#{action}\t\t\t"
    #    end.join("\t")
    #  ].join("\t")

    self.where(:date.gte => Date.new(2020, 1, 1)).each do |tl|
      print = [tl.date.strftime("%d/%m/%Y")]

      cur = {}

      fields.except('_id', 'date').keys.each do |action|
        if time = tl.send(action)
          time = Time.at(time)
          if time.year < 2020
            time = time.in_time_zone('Jakarta')
          end
          print << time.hour
          print << ":"
          print << time.min
          print << time.hour * 60 + time.min
          hasht[action.to_sym] << time.hour * 60 + time.min
          hasht[action.to_sym].sort!
          cur[action.to_sym] = time.hour * 60 + time.min
        else
          print << ([""] * 4).flatten
        end
      end

      hasht.keys.each do |action|
        size = hasht[action].size
        av = hasht[action].sum / size
        me = size % 2 == 0 ? ((hasht[action][size / 2 - 1] + hasht[action][size / 2]) / 2).to_i : hasht[action][size / 2]
        gopr(print, av)
        gopr(print, me)
      end

      prints << print.join("\t")
      print = []

      wd = cur[:work_finished] - cur[:work_start] rescue 0
      gd = cur[:work_start] - cur[:go] rescue 0
      hd = cur[:home] - cur[:work_finished] rescue 0
      tc = gd + hd

      gopr(print, wd)
      gopr(print, gd)
      gopr(print, hd)
      gopr(print, tc)

      hash2.keys.each do |action|
        hash2[action] << eval(action.to_s)
        hash2[action].sort!

        size = hash2[action].size
        av = hash2[action].sum / size
        me = size % 2 == 0 ? ((hash2[action][size / 2 - 1] + hash2[action][size / 2]) / 2).to_i : hash2[action][size / 2]
        gopr(print, av)
        gopr(print, me)
      end

      prints2 << print.join("\t")
    end

    prints.join("\n") + "\n\n\n" + prints2.join("\n")
  end

  def self.gopr(print, uu)
    print << uu / 60
    print << ':'
    print << uu % 60
    print << uu
  end
end
