class UserMovement

  require "rubygems"
  require 'json'
  require "sqlite3"
  require 'csv'

  # Range of acceptable values
  #37.783333 -122.436667 to 
  #37.743333 -122.396667

  # starting coordinates taken from wikipedia - but changed to make absolute corner
  SF_longitude = 37.743333
  SF_latitude = -122.396667
  Square_size = 0.040000
  Square_size_num = 40000
  Square_size_denom = 1000000
  # allow for 100m difference
  Difference_100m = 0.0001


  def initialize()
    @db_name2 = "sf_db.sqlite3"
    
    puts "1) make sample and read_csv or \n2) analyze data?"
    print "> "
    action = gets.chomp().to_i
    
    if action == 1
      sample_users = 1000
      make_user_data(sample_users)
    elsif action == 2
      longitudes_lookup = [37.758973, 37.77771, 37.764514]
      latitudes_lookup = [-122.429914, -122.431361, -122.418523]

      Q1_analyze_user_data(10, longitudes_lookup, latitudes_lookup)

      Q2_analyze_user_data(37.758973, -122.429914)

      # Q3_analyze_user_data(37.758973, -122.429914, 1, 2)
    end
  end

  def make_user_data(n_sample_users)
    # make db to write to
    make_db()
    # open db to work with
    db = SQLite3::Database.open @db_name2

    # redo user movements to capture for n users
    for n in (1..n_sample_users)
      # open new CSV for user
      CSV.open("csv/user_#{n}.csv", "w") do |csv|

        # reiterate for ts for a given timestamp
        # use base of 90 timestamps with max of 111 timestamps for a given user
        for ts in (1..(90 + rand(20)))
          if ts == 1
            # make random start time between 7am and 10am
            time_stamp = Time.new( 2013, 03, 05, (7 + rand(3)), (rand(60)) )
            
            # from start position we want users to be anywhere in box to start
            # we use 0.04 as mox area for users to move around - this allows users to start anywhere in box area in SF
            rand_start_spot = (rand(Square_size_num).to_f / Square_size_denom )
            user_long = SF_longitude + rand_start_spot
            user_lat = SF_latitude - rand_start_spot
             print  user_long, " ", user_lat, " to "
            # write to csv
            # csv << [time_stamp, user_long, user_lat]
          end

          # random interval up to 10 minutes
          time_stamp = time_stamp + rand(600)

          # 100 chances to end up in sqaure space
          for k in 0..100
            #create new random movements for users
            long_random = (rand(Square_size_num/2).to_f / (Square_size_denom * 10) )
            lat_random = (rand(Square_size_num/2).to_f / (Square_size_denom * 10) )

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

          # round values
          user_long = user_long.round(6)
          user_lat = user_lat.round(6)

          # write to CSV
          csv << [time_stamp, user_long, user_lat]

          # write to db
          db.execute( "INSERT INTO user_data (user, date_time, longitude, latitude) VALUES 
            ('#{n}', '#{time_stamp}', '#{user_long}', '#{user_lat}') ;") 
        end
        print  user_long, " ", user_lat, "\n"
        # puts "_" * 20
      end
    end

    #read in csv to database
    #read_csv(n_sample_users)
    db.close
  end

  def make_db()
    File.delete(@db_name2) if File.exist?(@db_name2);
    db = SQLite3::Database.new(@db_name2);

    # create table for schedule
    db.execute("CREATE TABLE user_data (
      user INTEGER,
      date_time DATETIME,
      longitude INTEGER,
      latitude INTEGER
    );")

    db.close()
  end

  def read_csv(n_sample_users)
    make_db()

    for n in (1..n_sample_users)
      # open new CSV for user
      #CSV.open("user_#{n}.csv", "r") do |csv|
      CSV.foreach("csv/user_#{n}.csv") do |row|
        db.execute( "INSERT INTO user_data (user, date_time, longitude, latitude) VALUES 
          ('#{n}', '#{row[0]}', '#{row[1]}', '#{row[2]}') ;")
      end
    end
  end

  def Q1_analyze_user_data(time_to_lookup_q1_hour, longitudes_lookup, latitudes_lookup)
    db = SQLite3::Database.open @db_name2
    
    # enter hour to time to get range to check for
    time_to_lookup_q1 = Time.new( 2013, 03, 05, time_to_lookup_q1_hour )
    time_to_lookup_q1_end = time_to_lookup_q1 + 3600

    # check database to see how many times location has been visited
    longitudes_lookup.length.times do |long_lat_lookup|
      upper_long = ((longitudes_lookup[long_lat_lookup]).to_f + Difference_100m)
      lower_long = ((longitudes_lookup[long_lat_lookup]).to_f - Difference_100m)
      upper_lat = ((latitudes_lookup[long_lat_lookup]).to_f - Difference_100m)
      lower_lat = ((latitudes_lookup[long_lat_lookup]).to_f + Difference_100m)

      users_near = db.execute("SELECT * FROM user_data WHERE 
        (longitude BETWEEN #{lower_long} AND #{upper_long} AND latitude BETWEEN #{upper_lat} AND #{lower_lat} AND
          date_time BETWEEN '#{time_to_lookup_q1}' AND '#{time_to_lookup_q1_end}');")

      print "\nLocation #{long_lat_lookup} had ", users_near.count, " user(s) "
      puts ""
    end
  end

  def Q2_analyze_user_data(longitudes_lookup_q2, latitudes_lookup_q2)
    db = SQLite3::Database.open @db_name2

    # check database to see how many times location has been visited
    upper_long = (longitudes_lookup_q2 + Difference_100m)
    lower_long = (longitudes_lookup_q2 - Difference_100m)
    upper_lat = (latitudes_lookup_q2 - Difference_100m)
    lower_lat = (latitudes_lookup_q2 + Difference_100m)

    users_near_q2 = db.execute("SELECT date_time FROM user_data WHERE 
      (longitude BETWEEN #{lower_long} AND #{upper_long} AND latitude BETWEEN #{upper_lat} AND #{lower_lat});")

    print "\nLocation had ", users_near_q2.count, " user(s) throughout the day\n"
    print users_near_q2.sort
    puts ""
  end

  def Q3_analyze_user_data(longitudes_lookup_q3, latitudes_lookup_q3, question3_user1, question3_user2)
    db = SQLite3::Database.open @db_name2

    # check database to see how many times location has been visited
    upper_long = (longitudes_lookup_q3 + Difference_100m)
    lower_long = (longitudes_lookup_q3 - Difference_100m)
    upper_lat = (latitudes_lookup_q3 - Difference_100m)
    lower_lat = (latitudes_lookup_q3 + Difference_100m)

    users1_q3 = db.execute("SELECT * FROM user_data WHERE (user = ? );", (question3_user1))
    users2_q3 = db.execute("SELECT * FROM user_data WHERE (user = ? );", (question3_user2))

    print "\nLocation had ", users1_q3.count, " user(s) throughout the day\n"
    print users1_q3
    puts ""
  end
end

make_csvs = UserMovement.new()
