class LRUCache
  def initialize(size = 1000)
    @size = size
    @store = {}
    @lru = []
  end

  def []=(key, value)
    @store[key] = value
    set_lru(key)
    @store.delete(@lru.pop) if @lru.size > @size
  end

  def [](key)
    set_lru(key)
    @store[key]
  end

  def keys
    @store.keys
  end

  def values
    @store.values
  end

  private

  def set_lru(key)
    @lru.unshift(@lru.delete(key) || key)
  end
end
