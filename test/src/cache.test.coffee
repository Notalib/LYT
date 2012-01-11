# Requires `/support/lyt/cache`

module "cache"

test "writing and reading", ->
  LYT.cache.write "test", "string", "stringdata"
  LYT.cache.write "test", "obj",    { str: "value", arr: [1, 2, 3] }
  
  equal LYT.cache.read("test", "string"), "stringdata"
  deepEqual LYT.cache.read("test", "obj"), { str: "value", arr: [1, 2, 3] }

