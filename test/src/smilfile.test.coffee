module "SMILDocument"

asyncTest "Basics", 4, ->
  file = new LYT.SMILDocument "/test/fixtures/smiltest.smil"
  file.done ->
    console.log file.pars
    par = file.getParByTime()
    equal par.id,       "rgn_par_test_0001"
    equal par.text.src, "0000.htm#rgn_cnt_0009"
    
    par = file.getParByTime 23
    equal par.id,       "rgn_par_test_0004"
    equal par.text.src, "0000.htm#rgn_cnt_0012"
  file.fail ->
    console.log arguments
    equal false, true
  file.always -> start()
  
