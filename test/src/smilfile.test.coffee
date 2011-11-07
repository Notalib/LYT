module "SMILFile class"


test "Basics", ->
  file = new LYT.SMILFile "fixtures/smil.smil"
  equal file.sequences[0].duration,             2114.22
  equal file.sequences[0].contents[0].id,       "rgn_par_0007_0001"
  equal file.sequences[0].contents[0].text.src, "15000.htm#rgn_cnt_0480"
  equal file.sequences[0].contents[0].audio.src, "dtb_0007.mp3"
  equal file.sequences[0].contents[0].audio.end, 4.706
  #equal file.