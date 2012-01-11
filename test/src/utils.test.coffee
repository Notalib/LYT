# Requires `/support/lyt/utils`

module "utils/time"

test "parseTime", ->
  equal LYT.utils.parseTime( false ),      0, "Shold return 0 on bad input"
  equal LYT.utils.parseTime( "monkey!" ),  0, "Shold return 0 on bad input"
  equal LYT.utils.parseTime( "00:01" ),    1
  equal LYT.utils.parseTime( "00:00:01" ), 1
  equal LYT.utils.parseTime( "01:00" ),    60
  equal LYT.utils.parseTime( "00:01:00" ), 60
  equal LYT.utils.parseTime( "1:00:00" ),  3600
  equal LYT.utils.parseTime( "1:02:03" ),  3723

test "formatTime", ->
  equal LYT.utils.formatTime( 0 ),     "0:00:00"
  equal LYT.utils.formatTime( -31 ),   "0:00:00"
  equal LYT.utils.formatTime( 1 ),     "0:00:01"
  equal LYT.utils.formatTime( 60 ),    "0:01:00"
  equal LYT.utils.formatTime( 3600 ),  "1:00:00"
  equal LYT.utils.formatTime( 3723 ),  "1:02:03"
  equal LYT.utils.formatTime( 39723 ), "11:02:03"

