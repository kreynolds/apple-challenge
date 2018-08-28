require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest

  setup do
    Visit.truncate
  end

  test "top_urls returns empty json with no data" do
    get '/top_urls'
    assert_equal 200, status
    assert_equal "application/json; charset=utf-8", response.headers['Content-Type']
    assert JSON.parse(response.body).empty?
  end

  test "top_urls returns 5 days of json with 10 days of hits" do
    10.times do |i|
      assert Visit.create(url: 'http://apple.com', created_at: Time.now - i.days)
    end

    get '/top_urls'
    data = JSON.parse(response.body)

    assert_equal 5, data.size
  end

  test "top_urls aggregates hits for the same url in the same day" do
    ts = Time.now
    date = ts.strftime('%Y-%m-%d')

    n = 5
    n.times do |i|
      assert Visit.create(url: 'http://apple.com', created_at: ts)
    end

    get '/top_urls'
    data = JSON.parse(response.body)

    assert data[date]
    assert_equal n, data[date][0]['visits']
    assert_equal 'http://apple.com', data[date][0]['url']
  end

  test "top_urls correctly counts hits per url per day" do
    ts = Time.now
    today = ts.strftime('%Y-%m-%d')
    yesterday = (ts - 1.day).strftime('%Y-%m-%d')

    # Create some hits
    2.times do |day|
      3.times do |i|
        assert Visit.create(url: 'http://apple.com', created_at: Time.now - day.days)
      end
      5.times do |i|
        assert Visit.create(url: 'http://store.apple.com', created_at: Time.now - day.days)
      end
    end

    get '/top_urls'
    data = JSON.parse(response.body)

    assert data[today][0][:visits] = 5
    assert data[today][0][:url] = 'http://apple.com'
    assert data[today][1][:visits] = 3
    assert data[today][1][:url] = 'http://store.apple.com'

    assert data[yesterday][0][:visits] = 5
    assert data[yesterday][0][:url] = 'http://apple.com'
    assert data[yesterday][1][:visits] = 3
    assert data[yesterday][1][:url] = 'http://store.apple.com'
  end

  test "top_referers returns empty json with no data" do
    get '/top_referers'
    assert_equal 200, status
    assert_equal "application/json; charset=utf-8", response.headers['Content-Type']
    assert JSON.parse(response.body).empty?
  end

  test "top_referers returns 5 days of json with 10 days of hits" do
    10.times do |i|
      assert Visit.create(url: 'http://apple.com', created_at: Time.now - i.days)
    end

    get '/top_referers'
    data = JSON.parse(response.body)

    assert_equal 5, data.size
  end

  test "top_referers aggregates hits for the same url in the same day" do
    ts = Time.now
    date = ts.strftime('%Y-%m-%d')

    n = 5
    n.times do |i|
      assert Visit.create(url: 'http://apple.com', created_at: ts)
    end

    get '/top_referers'
    data = JSON.parse(response.body)

    assert data[date]
    assert_equal n, data[date][0]['visits']
    assert_equal 'http://apple.com', data[date][0]['url']
  end

  test "top_referers correctly counts hits per url per day" do
    ts = Time.now
    today = ts.strftime('%Y-%m-%d')
    yesterday = (ts - 1.day).strftime('%Y-%m-%d')

    # Create some hits
    2.times do |day|
      3.times do |i|
        assert Visit.create(url: 'http://apple.com', created_at: Time.now - day.days)
      end
      5.times do |i|
        assert Visit.create(url: 'http://store.apple.com', created_at: Time.now - day.days)
      end
    end

    get '/top_referers'
    data = JSON.parse(response.body)

    assert data[today][0][:visits] = 5
    assert data[today][0][:url] = 'http://apple.com'
    assert data[today][1][:visits] = 3
    assert data[today][1][:url] = 'http://store.apple.com'

    assert data[yesterday][0][:visits] = 5
    assert data[yesterday][0][:url] = 'http://apple.com'
    assert data[yesterday][1][:visits] = 3
    assert data[yesterday][1][:url] = 'http://store.apple.com'
  end

  test "top_referers returns (direct) with no referer" do
    ts = Time.now
    assert Visit.create(url: 'http://apple.com', created_at: Time.now)
    today = ts.strftime('%Y-%m-%d')

    get '/top_referers'
    data = JSON.parse(response.body)

    assert_equal 1, data[today][0]['referers'].size
    assert_equal '(direct)', data[today][0]['referers'][0]['url']
    assert_equal 1, data[today][0]['referers'][0]['visits']
  end

  test "top_referers returns specified referer" do
    ts = Time.now
    assert Visit.create(url: 'http://apple.com', created_at: Time.now, referer: 'http://store.apple.com')
    today = ts.strftime('%Y-%m-%d')

    get '/top_referers'
    data = JSON.parse(response.body)

    assert_equal 'http://store.apple.com', data[today][0]['referers'][0]['url']
  end

  test "top_referers returns only 5 referers" do
    ts = Time.now
    today = ts.strftime('%Y-%m-%d')

    # Add 20 visits with >= 6 distinct referers
    20.times do |i|
      assert Visit.create(url: 'http://apple.com', created_at: ts, referer: "http://store.apple.com/#{i % 6}")
    end

    get '/top_referers'
    data = JSON.parse(response.body)
    referers = data[today][0]['referers']

    # Check to make sure only 5 referers come back for this date
    assert_equal 5, referers.size

    # Check to make sure they are in sorted order
    assert referers.first['visits'] > referers.last['visits']

    # The first referer should have 4 hits
    assert_equal 4, referers.first['visits']
  end
end
