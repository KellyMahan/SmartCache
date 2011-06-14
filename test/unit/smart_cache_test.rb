require 'test_helper'


#written within a test rails application
class SmartCacheTest < ActiveSupport::TestCase
  
  require 'digest/md5'
  
  test "long caching data" do
    time_to_live = 1.day
    product = SmartCache.block_cache("product_first", time_to_live) do
      Product.first
    end
    assert product.is_a?(Product), "Returned item is not a Product"
    assert Rails.cache.read("product_first").is_a?(Product)
    assert_equal "Product Two", product.name
    
  end
  
  test "caching data" do
    cart = Cart.order(:id).smart_cache.first
    cart2 = Rails.cache.read(Digest::MD5.hexdigest(Cart.order(:id).to_sql)).first
    assert cart.is_a?(Cart), "Returned item is not cart"
    assert_equal cart2, cart
  end

  test "standard cache find" do
    cart = Cart.find(Cart.first.id)
  end
  
end