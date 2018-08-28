# NOTE: This could be a separate rake task, or a separate configurable object that is called
#       from here, but its here as is for simplicity

# Set a batch size for bulk inserts, 10k is about the sweet spot on test hardware
batch_size = 10_000
total_records = 1_000_000

# Potential set of domains. Some required and some optional ones
# 11 added here to test the limits as set in the report
urls = %w{
  http://apple.com
  https://apple.com
  https://www.apple.com
  http://developer.apple.com
  http://en.wikipedia.org
  http://opensource.org
  http://store.apple.com
  http://siri.apple.com
  http://www.google.com
  http://www.google.co.uk
  http://www.apple.co.uk
}

# Create a timestamp only once and use random offsets from it over the last 10 days
ts = Time.now

# Truncate the table and start over
print  "Truncating the visits table and inserting #{total_records} records. Hit ctrl-c to abort ... "
5.times do |i|
  print "#{(5 - i)} "
  sleep 1
end
print "\n"
Visit.truncate

# Run through and create a number of batches as required
(total_records / batch_size).times do |i|
  # Array of rows to insert
  multi_insert = []

  batch_size.times do |j|
    # Get a random url
    url = urls.sample

    # 4/5 of urls have a referer
    referer = if rand >= 0.2
      urls.sample
    end

    # Pick a random time in the last 10 days
    created_at = ts - rand(864_000)

    # Add the newly created row the multi-insert
    multi_insert << [url, referer, created_at]
  end

  # Import the data in bulk
  Visit.import([:url, :referer, :created_at], multi_insert)

  puts "Inserted #{(i+1)*batch_size} rows"
end

# This runs at about 18k/s on my laptop, I don't bother to disable/re-enable indexes or any other tricks
elapsed = Time.now - ts
puts "Inserted #{total_records} records in #{elapsed.round(2)} seconds; #{(total_records / elapsed).round(2)}/s"