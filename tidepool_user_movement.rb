class UserMovement

  require "rubygems"
  require 'json'
  # require 'net/http'
  require "sqlite3"
  require 'csv'

  # 37.783333, -122.436667
  # starting coordinates taken from wikipedia - but changed to make absolute corner
  SF_longitude = 37.763333
  SF_latitude = -122.456667

  def initialize
    puts "1. make sample or \n2. read_csv or \n3. analyze data?"
    print "> "
    action = gets.chomp().to_i
    
    if action == 1
      sample_users = prompt()
      make_user_data(sample_users)
    elsif action == 2
      sample_users = prompt()
      read_csv(sample_users)
    elsif action == 3
      analyze_user_data()
    end;
  end

  def prompt()
    puts "how many sample users?"
    print "> "
    gets.chomp().to_i
  end

  def make_user_data(n_sample_users)
    # max change of coordinates +- .02 degrees

    # redo user movements to capture for n users
    for n in (1..n_sample_users)
      # open new CSV for user
      CSV.open("user_#{n}.csv", "w") do |csv|

        # reiterate for ts for a given timestamp
        # use base of 90 timestamps with max of 111 timestamps for a given user
        for ts in (1..(89 + rand(20)))
          if ts == 1
            # make random start time between 7am and 10am
            time_stamp = Time.new( 2013, 03, 05, (7 + rand(3)), (rand(60)) )
            
            # from start position we want users to be anywhere in box to start
            # we use 0.04 as mox area for users to move around - this allows users to start anywhere in box area in SF
            rand_start_spot = (rand(40000).to_f / 1000000 )
            user_long = SF_longitude + rand_start_spot
            user_lat = SF_latitude + rand_start_spot
            print  user_long, " ", user_lat, "\n"
            # write to csv
            csv << [time_stamp, user_long, user_lat]
          end

          # random interval up to 10 minutes
          time_stamp = time_stamp + rand(600)

          # to randomize movement in any direction
          random_movement = rand(4)
          if random_movement == 0
            user_long = user_long + (rand(20000).to_f / 10000000 )
            user_lat = user_lat + (rand(20000).to_f / 10000000 )
          elsif random_movement == 1
            user_long = user_long + (rand(20000).to_f / 10000000 )
            user_lat = user_lat - (rand(20000).to_f / 10000000 )
          elsif random_movement == 2
            user_long = user_long - (rand(20000).to_f / 10000000 )
            user_lat = user_lat + (rand(20000).to_f / 10000000 )
          elsif random_movement == 3       
            user_long = user_long - (rand(20000).to_f / 10000000 )
            user_lat = user_lat - (rand(20000).to_f / 10000000 )
          end

          # write to CSV
          csv << [time_stamp, user_long, user_lat]
          
          # time_stam, " ",
          # print  user_long, " ", user_lat, "\n"
          #print rand(4)
        end
        print  user_long, " ", user_lat, "\n"
        puts "_" * 20
      end
    end
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
          date DATE,
          longitude INTEGER,
          latitude INTEGER
        );")
      end

      # open new CSV for user
      #CSV.open("user_#{n}.csv", "r") do |csv|
      CSV.foreach("user_#{n}.csv") do |row|
        db.execute( "INSERT INTO user_data (user, date, longitude, latitude) VALUES 
          ('#{n}', '#{row[0]}', '#{row[1]}', '#{row[2]}') ;")
      end
    end
  end

  def analyze_user_data()
    db = SQLite3::Database.open "sf_db.sqlite3"

  end
end

make_csvs = UserMovement.new()
# a_game.play()
