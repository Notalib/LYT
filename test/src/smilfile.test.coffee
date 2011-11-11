module "SMILDocument class"

asyncTest "Basics", 4, ->
  file = new LYT.SMILDocument "fixtures/smil.smil"
  file.done ->
    console.log file.pars
    par = file.getParByTime()
    console.log par
    equal par.id,       "rgn_par_0007_0001"
    equal par.text.src, "15000.htm#rgn_cnt_0480"
    
    par = file.getParByTime 7.23
    equal par.id,       "rgn_par_0007_0002"
    equal par.text.src, "15000.htm#rgn_cnt_0481"
  file.fail ->
    console.log arguments
    equal false, true
  file.always -> start()
  
