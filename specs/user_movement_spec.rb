require '/Users/mmsanghvi/code/ruby/tidepool/lib/tidepool_user_movement'

make_sf_user_data = UserMovement.new()

make_sf_user_data.make_user_data(1000)

longitudes_lookup = [37.758973, 37.77771, 37.764514]
latitudes_lookup = [-122.429914, -122.431361, -122.418523]

# question 1
make_sf_user_data.Q1_analyze_user_data(10, longitudes_lookup, latitudes_lookup)
# question 2
make_sf_user_data.Q2_analyze_user_data(37.758973, -122.429914)

#make_sf_user_data.Q3_analyze_user_data(37.758973, -122.429914, 1, 2)
