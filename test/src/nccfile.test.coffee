module "NCCFile class"

asyncTest "Basics", 3, ->
  file = new LYT.NCCDocument "fixtures/ncc.html"
  file.then ->
    equal file.creators(), "Richard G. Lipsey, Paul N. Courant, Douglas D. Purvis & Peter O. Steiner"
    equal file.metadata.totalTime.content, "91:27:21"
    equal file.structure.length, 6
  file.fail ->
    console.log arguments
  file.always ->
    start()
  
