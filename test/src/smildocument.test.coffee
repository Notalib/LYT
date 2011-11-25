module "SMILDocument"

asyncTest "Basics", 4, ->
  file = new LYT.SMILDocument "/test/fixtures/smiltest.smil"
  file.done ->
    clip = file.getClipByTime()
    equal clip.id,       "rgn_par_test_0001"
    equal clip.text.src, "0000.htm#rgn_cnt_0009"
    
    clip = file.getClipByTime 23
    equal clip.id,       "rgn_par_test_0004"
    equal clip.text.src, "0000.htm#rgn_cnt_0012"
  
  file.fail ->
    console.log arguments
    equal false, true
  file.always -> start()
  
