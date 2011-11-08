module "SMILDocument class"

asyncTest "Basics", 9, ->
  file = new LYT.SMILDocument "fixtures/smil.smil"
  file.done ->
    equal file.sequences[0].duration,             2114.22
    equal file.sequences[0].segments[0].id,       "rgn_par_0007_0001"
    equal file.sequences[0].segments[0].end,       4.706
    equal file.sequences[0].segments[0].text.src, "15000.htm#rgn_cnt_0480"
    equal file.sequences[0].segments[0].audio.src, "dtb_0007.mp3"
    
    media = file.mediaFor()
    equal media.id,       "rgn_par_0007_0001"
    equal media.text.src, "15000.htm#rgn_cnt_0480"
    
    media = file.mediaFor 7.23
    equal media.id,       "rgn_par_0007_0002"
    equal media.text.src, "15000.htm#rgn_cnt_0481"
  file.fail ->
    console.log arguments
    equal false, true
  file.always -> start()
  
