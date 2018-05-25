class RickyDifaBot::ToDoList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :id_int, type: Integer
  field :name, type: String
  field :list, type: Hash, default: {}

  validates_uniqueness_of :id_int

  index({ id_int: 1 }, { background: true, unique: true })

  before_validation :name_and_id, on: :create

  DEFAULT_SUBLIST = '000-default'

  def add(items, sublist)
    sublist ||= DEFAULT_SUBLIST
    sublist.downcase!
    list[sublist] ||= []
    list[sublist] << items.map(&:downcase)
    list[sublist] = list[sublist].flatten.uniq.sort
    save
  rescue
    false
  end

  def remove(indices)
    keys_count = list.map { |k, v| v.size.times.map { |i| "#{k}::#{i}" } }.flatten.sort

    indices = indices.group_by { |idx| keys_count[idx].split('::')[0] }
    dup_list = list.deep_dup

    removed = []
    emptied_keys = []
    indices.each do |sublist, idxs|
      idxs.each do |idx|
        internal_index = keys_count[idx].split('::')[1].to_i
        removed << dup_list[sublist][internal_index]
        # WRONG LOGIC FOR MULTIPLE INDICES
        list[sublist].delete_at(internal_index)
        emptied_keys << sublist if list[sublist].size == 0
      end
    end

    list.except!(*emptied_keys)
    save
    removed
  end

  def move(indices, sublist)
    moved = remove(indices)
    add(moved, sublist)
    moved
  end

  def to_s
    Cachy.cache(:ricky_difa_bot, :to_do_list, name, updated_at) do
      res = ["id ##{id_int}: #{name}"]
      res << ''
      idx = 0
      list.keys.sort.each do |sublist|
        res << sublist unless sublist == DEFAULT_SUBLIST
        list[sublist].each_with_index do |item|
          res << "#{idx + 1}. #{item}"
          idx += 1
        end
        res << ''
      end
      res.join("\n")
    end
  end

  private

  def name_and_id
    self.name.downcase!
    self.id_int = (self.class.order_by(id_int: :asc).last.id_int.to_i + 1) rescue 0
  end
end
