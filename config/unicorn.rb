# config/unicorn.rb

worker_processes Integer(ENV['WEB_CONCURRENCY'] || 3)
timeout Integer(ENV['WEB_TIMEOUT'] || 15)
preload_app true

before_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
    
  if CassandraMigrations::Cassandra.client
    CassandraMigrations::Cassandra.shutdown!
  end
end  

after_fork do |server, worker|

  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
  
  Rails.logger.info "Unicorn process forked: connecting to Cassandra..."
  CassandraMigrations::Cassandra.start!
end