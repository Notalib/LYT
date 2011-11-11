module "utils/time"

test "parseTime", ->
  equal parseTime( false ),      0, "Shold return 0 on bad input"
  equal parseTime( "monkey!" ),  0, "Shold return 0 on bad input"
  equal parseTime( "00:01" ),    1
  equal parseTime( "00:00:01" ), 1
  equal parseTime( "01:00" ),    60
  equal parseTime( "00:01:00" ), 60
  equal parseTime( "1:00:00" ),  3600
  equal parseTime( "1:02:03" ),  3723

test "formatTime", ->
  equal formatTime( 0 ),     "0:00:00"
  equal formatTime( -31 ),   "0:00:00"
  equal formatTime( 1 ),     "0:00:01"
  equal formatTime( 60 ),    "0:01:00"
  equal formatTime( 3600 ),  "1:00:00"
  equal formatTime( 3723 ),  "1:02:03"
  equal formatTime( 39723 ), "11:02:03"

