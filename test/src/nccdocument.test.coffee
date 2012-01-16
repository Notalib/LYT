# Requires `/models/book/dtb/nccdocument`

module "NCCDocument"

asyncTest "Basics", 2, ->
  file = new LYT.NCCDocument "/test/fixtures/ncctest.html"
  file.then ->
    equal file.getMetadata().totalTime.content, "10:19:56", "Total time should be 10:19:56"
    equal file.structure.length, 18, "DTB structure should be 18 nodes long"
  file.fail ->
    console.log arguments
  file.always ->
    start()
  
