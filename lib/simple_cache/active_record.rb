module ActiveRecord
  
  class Base
    include SmartCache
    EXPIRE_TIME = 10.minutes
    
    def update_attributes(attributes)
      if self.frozen?
        @attributes = @attributes.dup
      end
      super
    end
    
    def update_attributes!(attributes)
      if self.frozen?
        @attributes = @attributes.dup
      end
      super
    end
  end
  
  module FinderMethods
    
    require 'digest/md5'
    
    def find(*args)
      return to_a.find { |*block_args| yield(*block_args) } if block_given?

      options = args.extract_options!

      if options.present?
        apply_finder_options(options).find(*args)
      else
        case args.first
        when :first, :last, :all
          send(args.first)
        else
          if args.length==1
            #puts @klass.name
            cache_key = Digest::MD5.hexdigest("short_cache_by_id_#{@klass.name}_#{args[0]}")
            results = Rails.cache.read(cache_key)
            return results if results
            results = find_with_ids(*args)
            Rails.cache.write(cache_key, results, :expires_in => eval("#{@klass.name}::EXPIRE_TIME"))
            return results
          end
          find_with_ids(*args)
        end
      end
    end
  end
  
  class Relation
    require 'digest/md5'
    
    def clear_smart_cache
      cache_key = Digest::MD5.hexdigest(arel.to_sql)
      Rails.cache.write(cache_key, nil, :expires_in => 0.seconds)
    end
    
    def smart_cache(ttl = nil)
      return @records if loaded?
      cache_key = Digest::MD5.hexdigest(arel.to_sql)
      results = Rails.cache.read(cache_key)
      return results if results
      @records = eager_loading? ? find_with_associations : @klass.find_by_sql(arel.to_sql)

      preload = @preload_values
      preload +=  @includes_values unless eager_loading?
      preload.each {|associations| @klass.send(:preload_associations, @records, associations) }

      # @readonly_value is true only if set explicitly. @implicit_readonly is true if there
      # are JOINS and no explicit SELECT.
      readonly = @readonly_value.nil? ? @implicit_readonly : @readonly_value
      @records.each { |record| record.readonly! } if readonly

      @loaded = true
      # key_list = Rails.cache.read("short_cache_#{@klass.name}")
      # key_list = [] if key_list.nil?
      # key_list.push cache_key
      # Rails.cache.write("short_cache_#{@klass.name}", key_list)
      Rails.cache.write(cache_key, @records, :expires_in => eval("ttl || #{@klass.name}::EXPIRE_TIME"))
      @records
    end
  end
end