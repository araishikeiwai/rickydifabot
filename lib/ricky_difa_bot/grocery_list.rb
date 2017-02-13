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
    define_method("add_#{type}") do |item_arr|
      arr = send(type)
      arr.push(item_arr.map(&:downcase))
      arr.flatten!
      arr.uniq!
      arr.sort!
      send("#{type}=", arr)
      save
    end

    define_method("remove_#{type}") do |idx|
      arr = send(type)
      removed = arr[idx]
      if removed
        arr.delete_at(idx)
        send("#{type}=", arr)
        save
      end
      removed
    end
  end

  def remove(indices)
    short_idx = indices.select{ |idx| idx < short.size }
    mid_idx = indices.select{ |idx| idx >= short.size && idx < short.size + mid.size }.map{ |idx| idx - short.size }
    long_idx = indices.select{ |idx| idx >= short.size + mid.size && idx < short.size + mid.size + long.size }.map{ |idx| idx - short.size - mid.size }

    removed = []
    removed += short_idx.map{ |idx| short[idx] }
    removed += mid_idx.map{ |idx| mid[idx] }
    removed += long_idx.map{ |idx| long[idx] }

    short.delete_if.with_index{ |_, idx| short_idx.include?(idx) }
    mid.delete_if.with_index{ |_, idx| mid_idx.include?(idx) }
    long.delete_if.with_index{ |_, idx| long_idx.include?(idx) }
    save

    removed
  end

  def move(indices, type)
    moved = remove(indices)
    send("add_#{type}", moved)
    moved
  end

  def list
    Cachy.cache(:ricky_difa_bot, :grocery_list, updated_at) do
      res = []
      idx = 0
      TYPES.each do |type|
        res << "#{type}-term:"
        send(type).each_with_index do |item|
          res << "#{idx + 1}. #{item}"
          idx += 1
        end
        res << ''
      end
      res.join("\n")
    end
  end
end
