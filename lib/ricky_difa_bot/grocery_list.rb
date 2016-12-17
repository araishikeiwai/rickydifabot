class RickyDifaBot::GroceryList
  include Mongoid::Document
  include Mongoid::Timestamps

  TYPES = [:short, :mid, :long]

  TYPES.each do |type|
    field type, type: Array, default: []
  end

  def self.instance
    first_or_create
  end

  TYPES.each do |type|
    define_method("add_#{type}") do |item|
      arr = send(type)
      arr.push(item.downcase)
      arr.uniq!
      arr.sort!
      send("#{type}=", arr)
      save
    end

    define_method("remove_#{type}") do |idx|
      arr = send(type)
      arr.delete_at(idx)
      send("#{type}=", arr)
      save
    end
  end

  def list
    Cachy.cache(:ricky_difa_bot, :grocery_list, updated_at) do
      res = []
      TYPES.each do |type|
        res << "#{type}-term:"
        send(type).each_with_index do |item, idx|
          res << "#{idx + 1}. #{item}"
        end
        res << ''
      end
      res.join("\n")
    end
  end
end
