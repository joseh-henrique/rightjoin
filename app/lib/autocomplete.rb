class Autocomplete
  def initialize(popular_tags_array)
    trie = Trie.new
    hash = Hash.new
    popular_tags_array.each_with_index do |tag, i|
      index_one_tag(tag, i, trie)
      hash[i] = tag
    end
    
    @trie = trie # uses priority as value
    @hash = hash # maps priority to a tag active record object
    @created_at = Time.now
  end
  
  def created_at
    @created_at
  end
  
  def suggest(term, num_of_suggestions = 8)
    return [] if term.blank? || num_of_suggestions <= 0
    
    words = term.split
    
    second_to_last = words.at(-2) # second to last
    last = words.at(-1) # last
    
    first_pass_term = second_pass_term = nil
    if second_to_last.nil?
      first_pass_term = last
    else
      first_pass_term = "#{second_to_last} #{last}"
      second_pass_term = last if last.length > 2
    end
    
    tag_ids_array = @trie.find_prefix(first_pass_term).values.sort.uniq.first(num_of_suggestions)
    if tag_ids_array.size < num_of_suggestions && !second_pass_term.nil? && second_pass_term.length > 2
      tag_ids_array += @trie.find_prefix(second_pass_term).values.sort.uniq.first(num_of_suggestions)
    end
    
    tag_ids_array = tag_ids_array.uniq.first(num_of_suggestions)
    suggested_tags = tag_ids_array.collect do |id| 
      tag = @hash[id]
      {:label => tag.name, :id => tag.id}
    end
    suggested_tags
  end  
  
  private
  
  def index_one_tag(tag, i, trie)
    words = tag.name.downcase.split
    prev_word = nil
    words.each do |word|
      trie.insert("#{prev_word} #{word} ", i) unless prev_word.nil?
      prev_word = word
    end
    trie.insert("#{prev_word} ", i) unless prev_word.nil?
  end  
end