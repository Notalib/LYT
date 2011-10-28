module "NCCFile class"


test "Basics", ->
  file = new NCCFile "fixtures/ncc.html"
  equal file.creators(), "Richard G. Lipsey, Paul N. Courant, Douglas D. Purvis & Peter O. Steiner"
  equal file.metadata.totalTime.content, "91:27:21"
  equal file.structure.length, 6