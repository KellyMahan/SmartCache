module SmartCache
  
  VERSION = "0.0.1"
  
  def self.included(base)
    base.after_save :update_caching
  end
  
  def self.block_cache(key=nil, ttl=1.day)
    results = Rails.cache.read(key)
    return results if results
    results = yield
    Rails.cache.write(key, results, :expires_in => ttl)
    return results
  end
  
  def update_caching
    cache_key = Digest::MD5.hexdigest("short_cache_by_id_#{self.class.name}_#{self.id}")
    Rails.cache.write(cache_key, self, :expires_in => eval("#{self.class.name}::EXPIRE_TIME"))
    return true
  end
  
end

require 'smart_cache/active_record.rb'