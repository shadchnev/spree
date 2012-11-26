require 'singleton'

module Spree::Preferences

  class StoreInstance
    attr_accessor :persistence

    def initialize
      # puts "AF: persist initialize"
      @cache = Rails.cache
      @persistence = false
      load_preferences
    end

    def set(key, value, type)
      # puts "AF: set #{key} #{value} #{type}"
      @cache.write(key, value)
      persist(key, value, type)
    end

    def exist?(key)
      # puts "AF: exist? #{key}"
      @cache.exist?(key) || !!try_db(key)
    end


    def get(key)
      try_db(key)
    end

    def delete(key)
      # puts "AF: delete #{key}"
      @cache.delete(key)
      destroy(key)
    end

    private


    def try_db(key)
      val = @cache.read(key)
      if(!val)
        from_db = Spree::Preference.where(:key => key).first
        if(from_db)
          @cache.write(key, from_db.value)
          val = from_db.value
        end
      end
      val
    end

    def persist(cache_key, value, type)
      # puts "AF: persist #{cache_key} #{value} #{type}"
      return unless should_persist?

      preference = Spree::Preference.find_or_initialize_by_key(cache_key)
      preference.value = value
      preference.value_type = type
      preference.save
    end

    def destroy(cache_key)
      # puts "AF: destroy #{cache_key}"
      return unless should_persist?

      preference = Spree::Preference.find_by_key(cache_key)
      preference.destroy if preference
    end

    def load_preferences
      # puts "AF: load prefs"
      return unless should_persist?

      Spree::Preference.valid.each do |p|
        Spree::Preference.convert_old_value_types(p) # see comment
        # puts "AF: write #{p.key} #{p.value}"
        @cache.write(p.key, p.value)
      end
    end

    def should_persist?
      @persistence and Spree::Preference.table_exists?
    end

  end

  class Store < StoreInstance
    include Singleton
  end

end