
# replay apache logsat against a server

require 'open-uri'
require 'thread'


file="mynode.org.au-access.log"
server = "mynode.org.au"
worker_threads = 15

# worker queue
queue = Queue.new


# read the apache log file and create a set of jobs
lineno = 1
File.open( file, "r").each_line do |line|

	matches = /([^ ]*).*\[(.*)\].*GET (.*)\sHTTP/.match( line ).captures
	if matches.length == 3
		ip = matches[ 0] 
		date = matches[ 1] 
		url = matches[2]
	#	puts "'#{ip}' '#{date}' '#{url}'"
		request = "http://#{server}/#{url}"
		queue << request
	else
		puts "bad line:#{lineno}: #{line}"
	end
	lineno += 1
end

puts "items to process #{queue.length}"


# create a thread group to process the queue
total_count = queue.length
threads = []
worker_threads.times do |i|
  t = Thread.new do
    until queue.empty?
      # pop with the non-blocking flag set, this raises
      # an exception if the queue is empty, in which case
      # work_unit will be set to nil
      request = queue.pop(true) rescue nil
      if request
        # queue len is approx only
        puts "#{total_count - queue.length} of #{total_count} thread #{i}, #{request}"
        begin
          content = URI.parse( request ).read
        rescue Timeout::Error
          puts 'error, took too long, exiting...'
        rescue OpenURI::HTTPError
          puts 'error, http' 
        end

        puts "finished #{i}, received #{content.length} bytes"
      end
    end
    puts "exiting #{i}"
  end
  threads << t
end


# wait for threads to finish
threads.each() do |t|
  t.join()
end

