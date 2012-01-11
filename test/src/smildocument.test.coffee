# Requires `/models/book/dtb/smildocument`

module "SMILDocument"

asyncTest "Basics", 6, ->
  file = new LYT.SMILDocument "/test/fixtures/smiltest.smil"
  file.done ->
    clip = file.getSegmentByTime()
    equal clip.id,       "rgn_par_test_0001"
    equal clip.text.src, "0000.htm#rgn_cnt_0009"
    
    clip = file.getSegmentByTime 23
    equal clip.id,       "rgn_par_test_0004"
    equal clip.text.src, "0000.htm#rgn_cnt_0012"
    
    deepEqual file.getTextContentReferences(), ["0000.htm"]
    deepEqual file.getAudioReferences(), ["dtb_0004.mp3"]
  
  file.fail ->
    console.log arguments
    equal false, true
  file.always -> start()
  
