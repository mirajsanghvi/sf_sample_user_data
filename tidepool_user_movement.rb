class UserMovement

  require "rubygems"
  require 'json'
  # require 'net/http'
  require "sqlite3"
  require 'csv'

  # Range of acceptable values
  #37.783333 -122.436667 to 
  #37.743333 -122.396667

  # 37.783333, -122.436667
  # starting coordinates taken from wikipedia - but changed to make absolute corner
  SF_longitude = 37.743333
  SF_latitude = -122.396667
  Square_size = 0.040000

  def initialize
    puts "1) make sample and read_csv or \n2) analyze data?"
    print "> "
    action = gets.chomp().to_i
    
    if action == 1
      sample_users = prompt()
      make_user_data(sample_users)
    elsif action == 2
      analyze_user_data()
    end;
  end

  def prompt()
    puts "how many sample users?"
    print "> "
    gets.chomp().to_i
  end

  def make_user_data(n_sample_users)
    # redo user movements to capture for n users
    for n in (1..n_sample_users)
      # open new CSV for user
      CSV.open("user_#{n}.csv", "w") do |csv|

        # reiterate for ts for a given timestamp
        # use base of 90 timestamps with max of 111 timestamps for a given user
        for ts in (1..(90 + rand(20)))
          if ts == 1
            # make random start time between 7am and 10am
            time_stamp = Time.new( 2013, 03, 05, (7 + rand(3)), (rand(60)) )
            
            # from start position we want users to be anywhere in box to start
            # we use 0.04 as mox area for users to move around - this allows users to start anywhere in box area in SF
            rand_start_spot = (rand(40000).to_f / 1000000 )
            user_long = SF_longitude + rand_start_spot
            user_lat = SF_latitude - rand_start_spot
             print  user_long, " ", user_lat, " to "
            # write to csv
            # csv << [time_stamp, user_long, user_lat]
          end

          # random interval up to 10 minutes
          time_stamp = time_stamp + rand(600)

          for k in 0..100
            #create new random movements for users
            long_random = (rand(20000).to_f / 10000000 )
            lat_random = (rand(20000).to_f / 10000000 )

            # to randomize movement in any direction
            random_movement = rand(4)
            if random_movement == 0
              user_long = user_long + long_random
              user_lat = user_lat + lat_random
            elsif random_movement == 1
              user_long = user_long + long_random
              user_lat = user_lat - lat_random
            elsif random_movement == 2
              user_long = user_long - long_random
              user_lat = user_lat + lat_random
            elsif random_movement == 3       
              user_long = user_long - long_random
              user_lat = user_lat - lat_random
            end

            # test to make sure inside range accepted on map
            if (user_long >= SF_longitude && user_long <= SF_longitude + Square_size) && 
              (user_lat <= SF_latitude && user_lat >= SF_latitude - Square_size)
              break
            end
          end

          # write to CSV
          csv << [time_stamp, user_long.round(6), user_lat.round(6)]
          
          # print  user_long, " ", user_lat, "\n"
          #print rand(4)
        end
        print  user_long, " ", user_lat, "\n"
        puts "_" * 20
      end
    end

    #read in csv to database
    read_csv(n_sample_users)
  end

  def read_csv(n_sample_users)
    # redo user movements to capture for n users
    for n in (1..n_sample_users)
      if n == 1
        File.delete("sf_db.sqlite3") if File.exist?("sf_db.sqlite3");
        db = SQLite3::Database.new("sf_db.sqlite3");

        # create table for schedule
        db.execute("CREATE TABLE user_data (
          user INTEGER,
          date_time DATETIME,
          longitude INTEGER,
          latitude INTEGER
        );")
      end

      # open new CSV for user
      #CSV.open("user_#{n}.csv", "r") do |csv|
      CSV.foreach("user_#{n}.csv") do |row|
        db.execute( "INSERT INTO user_data (user, date_time, longitude, latitude) VALUES 
          ('#{n}', '#{row[0]}', '#{row[1]}', '#{row[2]}') ;")
      end
    end
  end

  def analyze_user_data()
    db = SQLite3::Database.open "sf_db.sqlite3"

    ## Question 1

    # prompt to figure out if use own coordinates or preloaded ones
    puts "Question 1:", "Would you like to: \n 1) enter your own coordinates and time or \n 2) use preloaded ones?"
    print "> "
    question1 = gets.chomp().to_i

    # array to store areas to look up in data
    longitudes_lookup = []
    latitudes_lookup = []

    if question1 == 1
      puts "enter hour to search for:"
      time_to_lookup_q1_hour = gets.chomp().to_i
      time_to_lookup_q1 = Time.new( 2013, 03, 05, time_to_lookup_q1_hour )
      i=0
      while i < 3
        puts "enter longitude and latitude data of a location to learn more about:"
        # store locations in an array
        print "longitude > "
        longitudes_lookup[i] = gets.chomp().to_i
        print "longitude > "
        latitudes_lookup[i] = gets.chomp().to_i
        i+=1
      end
    elsif question1 == 2
      # use 4pm
      time_to_lookup_q1 = Time.new( 2013, 03, 05, 16 )
      # sample spot 1
      longitudes_lookup[0] = 37.758973
      latitudes_lookup[0] = -122.429914
      # sample spot 2
      longitudes_lookup[1] = 37.77771
      latitudes_lookup[1] = -122.431361
      # sample spot 3
      longitudes_lookup[2] = 37.764514
      latitudes_lookup[2] = -122.418523
    end

    # enter hour to time to get range to check for
    time_to_lookup_q1_end = time_to_lookup_q1 + 3600
    # allow for 100m difference
    difference_100m = 0.0001

    # check database to see how many times location has been visited
    longitudes_lookup.length.times do |long_lat_lookup|
      upper_long = ((longitudes_lookup[long_lat_lookup]).to_f + difference_100m)
      lower_long = ((longitudes_lookup[long_lat_lookup]).to_f - difference_100m)
      upper_lat = ((latitudes_lookup[long_lat_lookup]).to_f - difference_100m)
      lower_lat = ((latitudes_lookup[long_lat_lookup]).to_f + difference_100m)

      users_near = db.execute("SELECT * FROM user_data WHERE 
        (longitude BETWEEN #{lower_long} AND #{upper_long} AND latitude BETWEEN #{upper_lat} AND #{lower_lat} AND
          date_time BETWEEN '#{time_to_lookup_q1}' AND '#{time_to_lookup_q1_end}');")

      print "\nLocation #{long_lat_lookup} had ", users_near.count, " user(s) "
      puts ""
    end


    ## Question 2
    puts ""

    # prompt to figure out if use own coordinates or preloaded ones
    puts "Question 2:", "Would you like to: \n 1) enter your own coordinates or \n 2) use a preloaded one?"
    print "> "
    question2 = gets.chomp().to_i

    if question2 == 1
      puts "enter longitude and latitude data of a location to learn more about:"
      # store locations in an array
      print "longitude > "
      longitudes_lookup_q2 = gets.chomp().to_i
      print "longitude > "
      latitudes_lookup_q2 = gets.chomp().to_i
    elsif question2 == 2
      # sample spot 1
      longitudes_lookup_q2 = 37.758973
      latitudes_lookup_q2 = -122.429914
    end

    # allow for 100m difference
    difference_100m = 0.0001

    # check database to see how many times location has been visited
    upper_long = (longitudes_lookup_q2 + difference_100m)
    lower_long = (longitudes_lookup_q2 - difference_100m)
    upper_lat = (latitudes_lookup_q2 - difference_100m)
    lower_lat = (latitudes_lookup_q2 + difference_100m)

    users_near_q2 = db.execute("SELECT date_time FROM user_data WHERE 
      (longitude BETWEEN #{lower_long} AND #{upper_long} AND latitude BETWEEN #{upper_lat} AND #{lower_lat});")

    print "\nLocation had ", users_near_q2.count, " user(s) throughout the day\n"
    print users_near_q2.sort
    puts ""


    ## Question 3
    puts ""

    # prompt to figure out if use own coordinates or preloaded ones
    puts "Question 3:", "Enter 2 users to test how often they end up 100m of each other?"
    print "1st User > "
    question3_user1 = gets.chomp().to_i
    print "2nd User > "
    question3_user2 = gets.chomp().to_i

    # allow for 100m difference
    difference_100m = 0.0001

    # check database to see how many times location has been visited
    upper_long = (longitudes_lookup_q2 + difference_100m)
    lower_long = (longitudes_lookup_q2 - difference_100m)
    upper_lat = (latitudes_lookup_q2 - difference_100m)
    lower_lat = (latitudes_lookup_q2 + difference_100m)

    users1_q3 = db.execute("SELECT * FROM user_data WHERE (user = ? );", (question3_user1))
    users2_q3 = db.execute("SELECT * FROM user_data WHERE (user = ? );", (question3_user2))

    print "\nLocation had ", users1_q3.count, " user(s) throughout the day\n"
    print users1_q3
    puts ""
  end
end

make_csvs = UserMovement.new()
# a_game.play()
