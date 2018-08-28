require 'test_helper'

class VisitTest < ActiveSupport::TestCase
  test "creates a hash without referer" do
    assert obj = Visit.create(url: 'http://apple.com', created_at: Time.now)
    assert obj.hash.present?
  end

  test "creates a hash with referer" do
    assert obj = Visit.create(url: 'http://apple.com', created_at: Time.now, referer: 'http://store.apple.com')
    assert obj.hash.present?
  end

  test "hashes differently depending on referer" do
    ts = Time.now
    obj1 = Visit.create(url: 'http://apple.com', created_at: ts)
    obj2 = Visit.create(url: 'http://apple.com', created_at: ts, referer: 'http://store.apple.com')
    assert_not_equal obj1.hash, obj2.hash
  end

  test "hashes differently depending on created_at" do
    obj1 = Visit.create(url: 'http://apple.com', created_at: Time.now, referer: 'http://store.apple.com')
    obj2 = Visit.create(url: 'http://apple.com', created_at: Time.now + 1, referer: 'http://store.apple.com')
    assert_not_equal obj1.hash, obj2.hash
  end

  test "hashes differently depending on url" do
    ts = Time.now
    obj1 = Visit.create(url: 'http://apple.com/us', created_at: ts, referer: 'http://store.apple.com')
    obj2 = Visit.create(url: 'http://apple.com', created_at: ts, referer: 'http://store.apple.com')
    assert_not_equal obj1.hash, obj2.hash
  end
end
