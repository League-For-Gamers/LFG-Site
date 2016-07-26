require 'concurrent'
require 'httpclient'

def build_main_feed_query(user)
  # Good god...
  own_query = "(SELECT * FROM posts WHERE user_id = #{user.id} AND group_id IS NULL)"
  following_query = "UNION (SELECT * FROM posts WHERE user_id IN (#{user.follows.map(&:following_id).join(",")}) AND group_id IS NULL)"

  Post.connection.unprepared_statement { "(#{own_query} #{following_query if user.follows.count > 0}) as posts" }
end

def open_output_csv(filename)
  file = File.open(filename, "w+")
  file.print  "Command,Server $hostname,Server Port," +
              "Document Path," +
              "Concurrency Level,Time taken for tests[s]," +
              "Complete requests,Failed requests," +
              "Total transferred[bytes],HTML transferred[bytes]," +
              "Requests per second[#/sec](mean),Time per request[ms](mean - across all concurrent requests)," +
              "Transfer rate[bytes/s]," +
              "Connect-min[ms],Connect-mean[ms],Connect-[+/-sd],Connect-median[ms],Connect-max[ms]," +
              "Processing-min[ms],Processing-mean[ms],Processing-[+/-sd],Processing-median[ms],Processing-max[ms]," +
              "Waiting-min[ms],Waiting-mean[ms],Waiting-[+/-sd],Waiting-median[ms],Waiting-max[ms]," +
              "Total-min[ms],Total-mean[ms],Total-[+/-sd],Total-median[ms],Total-max[ms]" +
              "\n"
  file
end

def end_output_csv(file, h, c)
  file.print  "c,#{h['Server $hostname']},#{h['Server Port']}," + 
              "#{h['Document Path']}," + 
              "#{h['Concurrency Level']},#{h['Time taken for tests'].scan(/[\d\.]+/).pop}," +
              "#{h['Complete requests']},#{h['Failed requests']}," + 
              "#{h['Total transferred'].scan(/\d+/).pop},#{h['HTML transferred'].scan(/\d+/).pop}," +
              "#{h['Requests per second'].scan(/[\d\.]+/).pop},#{h['Time per request'].scan(/[\d\.]+/).pop}," +
              "#{h['Transfer rate'].scan(/[\d\.]+/).pop}," + 
              "#{h['Connect'].gsub(/[\s\t]+/,',')},#{h['Processing'].gsub(/[\s\t]+/,',')},#{h['Waiting'].gsub(/[\s\t]+/,',')},#{h['Total'].gsub(/[\s\t]+/,',')}" +
              "\n"
  file.close
end

def run_command(command)
  h = {}
  IO.popen("ab -n #{command} 2>/dev/null", "r") do |io|
    while str = io.gets
      e = str.scan(/^(.+):\s+(.+)/)
      h[e[0][0]] = e[0][1] if e.length > 0
    end
  end
  h
end
def get_login_cookie(username)
  http = HTTPClient.new
  http.post("#{$host}/login", {'username': username, 'password': 'new_password'}).header["Set-Cookie"].last.split(";")[0]
end

namespace :bench do
  task :ab => :environment do
    puts "Setting up groups and users"
    # Get top 10 groups and users.
    top_10_groups = Group.select("groups.*", "(SELECT COUNT(*) FROM posts WHERE posts.group_id = groups.id) AS count").order("count DESC").limit(10)

    # I could *probably* make this a complicated single query but eh... I dun wanna.
    top_10_users = {}
    User.all.each do |user|
      c = Post.from(build_main_feed_query(user)).where(parent_id: nil).count
      top_10_users[user.username] = c
    end
    top_10_users = top_10_users.sort_by{ |user, count| count}.reverse[0, 10].map {|x| User.find_by(username: x[0]) }

    # Set predictable passwords
    top_10_users.each do |u|
      u.password = "new_password"
      u.password_confirmation = "new_password"
      u.save(validate: false)
    end

    pools = []
    threads = Concurrent::ThreadPoolExecutor.new(
      min_threads: 12,
      max_threads: 15,
      max_queue: 0
    )
    scaling_factor = 1.0
    base_requests_factor = 100_000
    $host = "http://127.0.0.1"

    puts "Beginning bench"

    # One thread making new posts for users and groups at 5 RPS
    new_entities = Concurrent::Future.execute(:executor => threads) do
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      loop do
        group = top_10_groups.shuffle.first
        user = top_10_users.shuffle.first
        # New random body post in a group
        Post.create(group: group, user: user, body: ((0...rand(400)).map { o[rand(o.length)] }.join))
        # New random body post in a user feed
        Post.create(user: user, body: ((0...rand(400)).map { o[rand(o.length)] }.join))
        # Run 5 times a second
        sleep(1.0/5.0)
      end
    end
    new_entities.execute

    # / Signup page
    # Error code 1
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup signup"
      
      con = (scaling_factor * 5).round # Concurrency
      reqs = (((base_requests_factor * con) / con) + 1) * con # Number of requests to run
      c = "#{reqs} -c #{con} -l '#{$host}/'" # Command
      
      file = open_output_csv("bench/signup.csv") # CSV log
      h = run_command(c)
      end_output_csv(file, h, c)

      puts "Finished signup"  
    end

    # Once per each group.
    # Group Timeline newer
    # Error code 2
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup group timeline newer"
      top_10_groups.each do |g|
        last_post_id = g.posts.order("id DESC").first.id # Latest post in a group
        
        con = (scaling_factor * 40).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Num Reqs / 10
        c = "#{reqs} -c #{con} -l '#{$host}/timeline?feed=group%2F#{g.slug}&id=#{last_post_id}&direction=newer'" # Command
        
        file = open_output_csv("bench/group_timeline_newer-#{g.slug}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished group timeline newer"
    end

    # Group Timeline older
    # Error code 3
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup group timeline older"
      top_10_groups.each do |g|
        last_post_id = g.posts.order("id DESC").limit(15).last.id # Last post in a group feed
        
        con = (scaling_factor * 20).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Num Reqs / 10
        c = "#{reqs} -c #{con} -l '#{$host}/timeline?feed=group%2F#{g.slug}&id=#{last_post_id}&direction=older'" # Command
        
        file = open_output_csv("bench/group_timeline_older-#{g.slug}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished group timeline older"
    end

    # User Timeline newer
    # Error code 4
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup user timeline newer"
      top_10_users.each do |u|
        # Last post made in the users feed.
        last_post_id = Post.from(build_main_feed_query(u)).where(parent_id: nil).limit(5).order("id DESC").first.id
        login_cookie = get_login_cookie(u.username) # Get login cookie

        con = (scaling_factor * 4).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Num Reqs / 10
        c = "#{reqs} -c #{con} -C #{login_cookie} -l '#{$host}/timeline?feed=main&id=#{last_post_id}&direction=newer'" # Command
        
        file = open_output_csv("bench/user_timeline_newer-#{u.username}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished user timeline newer"
    end

    # User Timeline older
    # Error code 5
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup user timeline older"
      top_10_users.each do |u|
        # Get last post from default user queue
        last_post_id = Post.from(build_main_feed_query(u)).where(parent_id: nil).limit(15).order("id DESC").last.id
        login_cookie = get_login_cookie(u.username) # Get login cookie
        
        con = (scaling_factor * 4).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Num Reqs / 10
        c = "#{reqs} -c #{con} -C #{login_cookie} -l '#{$host}/timeline?feed=main&id=#{last_post_id}&direction=older'" # Command
        
        file = open_output_csv("bench/user_timeline_older-#{u.username}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished user timeline older"
    end

    # Group show page
    # Error code 6
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup group page"
      top_10_groups.each do |g|
        con = (scaling_factor * 17).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Num requests / 10
        c = "#{reqs} -c #{con} -l '#{$host}/group/#{g.slug}'" # Command

        file = open_output_csv("bench/group_page-#{g.slug}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished group page"
    end

    # Login post
    # Error code 7
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup login"
      top_10_users.each do |u|
        # Write login data to tmp file.
        File.open("tmp/login_post", 'w+') { |f| f.write "utf8=%E2%9C%93&username=#{u.username}&password=new_password&commit=Log+In"}
        
        con = (scaling_factor * 2).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Requests / 10
        c = "#{reqs} -c #{con} -T application/x-www-form-urlencoded -p tmp/login_post -l '#{$host}/login'" # Command
        
        file = open_output_csv("bench/login-#{u.username}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished login"
    end

    # User show page
    # Error code 8
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup user page"
      top_10_users.each do |u|
        con = (scaling_factor * 2).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Num requests / 10
        c = "#{reqs} -c #{con} -l '#{$host}/user/#{u.username}'" # Command

        file = open_output_csv("bench/user_page-#{u.username}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished user page"
    end

    # Messages
    # Error code 9
    pools << Concurrent::Future.execute(:executor => threads) do
      puts "Startup messages"
      top_10_users.each do |u|
        # Acquire Login Cookie
        login_cookie = get_login_cookie(u.username)

        con = (scaling_factor * 2).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Number of requests / 10
        c = "#{reqs} -c #{con} -C #{login_cookie} -l '#{$host}/messages'" # Command

        file = open_output_csv("bench/messages-#{u.username}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished messages"
    end

    # User home feed
    # Error code 10
    pools << Concurrent::Future.execute(:executor => threads) do 
      puts "Startup home feed"
      top_10_users.each do |u|
        # Acquire login cookie
        login_cookie = get_login_cookie(u.username)
        
        con = (scaling_factor * 4).round # Concurrency
        reqs = ((((base_requests_factor / 10) * con) / con) + 1) * con # Number of requests / 10
        c = "#{reqs} -c #{con} -C #{login_cookie} -l '#{$host}/'" # Command
        
        file = open_output_csv("bench/user_feed-#{u.username}.csv")
        h = run_command(c)
        end_output_csv(file, h, c)
      end
      puts "Finished home feed"
    end

    pools.each {|x| x.execute}
    while true do
      map = pools.map(&:state).uniq
      break if !map.include? :unscheduled and !map.include? :pending and !map.include? :processing
      sleep(5)
    end 
    new_entities.cancel
    pools.each_with_index do |p, i|
      puts "#{i} failure: #{p.reason}" if p.rejected?
    end

    puts "Finished"
  end
end