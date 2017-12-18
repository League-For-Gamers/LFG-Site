environment ENV.fetch("RAILS_ENV") { "development" }

threads ENV.fetch("RAILS_MIN_THREADS") { 4 }, ENV.fetch("RAILS_MAX_THREADS") { 4 }
port 3000 if ENV.fetch("RAILS_ENV") {"development"} == "development"
bind 'unix://tmp/sockets/puma.sock'

preload_app!
# If you are preloading your application and using Active Record, it's
# recommended that you close any connections to the database before workers
# are forked to prevent connection leakage.
#
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted, this block will be run. If you are using the `preload_app!`
# option, you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, as Ruby
# cannot share connections between processes.
#
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart