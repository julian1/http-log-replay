
# play a set of generated urls against server

require 'open-uri'
require 'thread'

worker_threads = 15


# worker queue
queue = Queue.new

# queue some jobs, could just use map
(1..100).inject([]) { 
  puts "queinig url" 
  #queue << "http://devel01.localnet2:3000/" 
  queue << "http://devel01.localnet2:3000/test" 
  # queue << "http://www.google.com/"
}

# exit



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

        puts "finished #{i}, received #{content.length} bytes "
        puts "#{content}"
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

