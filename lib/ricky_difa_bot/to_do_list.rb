class RickyDifaBot::ToDoList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :id_int, type: Integer
  field :name, type: String
  field :list, type: Array, default: [[' ']]

  validates_uniqueness_of :id_int

  index({ id_int: 1 }, { background: true, unique: true })

  before_validation :name_and_id, on: :create

  def add(items, idx)
    title, *content = self.list[idx]
    content << items.flatten.map(&:downcase)
    content = content.flatten.uniq.sort
    self.list[idx] = [title, content].flatten
    save
  end

  def remove(title_idx, content_indices)
    return if content_indices.include?(0)
    removed = self.list[title_idx].each_with_index.map { |content, idx| idx.in?(content_indices) && content || nil }.compact
    self.list[title_idx] = self.list[title_idx].each_with_index.reject { |_content, idx| idx.in?(content_indices) }.map { |content, idx| content }
    save
    removed
  end

  def add_sublist(sublist)
    sublist.downcase!
    return if self.list.any? { |old_sublist, *content| old_sublist == sublist }
    new_list = self.list
    new_list[new_list.size] = [sublist]
    self.list = new_list.sort_by { |title, *content| title }
    save
  end

  def remove_sublist(sublist_idx)
    return if sublist_idx == 0
    removed = self.list[sublist_idx].first
    self.list.delete_at(sublist_idx)
    save
    removed
  end

  def sublist_count
    list.size
  end

  def contents_count
    list.sum { |title, *content| content.size }
  end

  def to_s
    #Cachy.cache(:ricky_difa_bot, :to_do_list, name, updated_at) do
      res = ["(##{id_int}) #{name}"]
      res << ''
      list.each_with_index do |sublist, idx|
        res << "(#{idx}) #{sublist.first}"
        sublist.each_with_index do |content, content_idx|
          next if content_idx == 0
          res << "#{idx}.#{content_idx} #{content}"
        end
        res << ''
      end
      res.join("\n")
    #end
  end

  private

  def name_and_id
    self.name.downcase!
    self.id_int = (self.class.order_by(id_int: :asc).last.id_int.to_i + 1) rescue 0
  end
end
