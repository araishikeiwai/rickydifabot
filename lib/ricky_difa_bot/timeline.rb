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
    prints <<
      [
        "Date",
        fields.except('_id', 'date').keys.map do |action|
          "#{action}\t\t\t"
        end.join("\t")
      ].join("\t")

    self.all.each do |tl|
      print = [tl.date.strftime("%d/%m/%Y")]

      fields.except('_id', 'date').keys.each do |action|
        if time = tl.send(action)
          time = Time.at(time)
          print << time.hour
          print << ":"
          print << time.min
          print << time.hour * 60 + time.min
        else
          print << ([""] * 4).flatten
        end
      end

      prints << print.join("\t")
    end

    prints.join("\n")
  end
end
