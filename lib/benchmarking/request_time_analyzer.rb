#!/usr/bin/ruby
#
# Calculates average response times based on raw
# request time output as produced with log_file_analyzer.sh

file = ARGV[0]

all_response_times = Array.new
session_time = Array.new

# Build up an array of arrays in order to calculate
# averages for each request. We have 7 requests per
# ./post_submissions#submit_files call.
counter = 1
File.readlines(file).each do |line|
  if counter < 7
    session_time.push(line.to_f)
    counter += 1
  elsif counter == 7
    session_time.push(line.to_f)
    all_response_times << session_time
    session_time = Array.new
    counter = 1
  end
end

# Merge rows by computing the average of each column
total_sessions = all_response_times.length

# Get an array with 7 columns initialized to 0
accumulators = Array.new(7, 0)
all_response_times.each do |row|
  (0..6).each do |i|
    accumulators[i] += row[i]
  end
end

# Calculate averages and do some funky rounding
avgs = accumulators.map{ |i| (((i/total_sessions) * 100).round)/100.0 }

puts "total sessions: #{total_sessions}\naverages: " + avgs.join(", ")



