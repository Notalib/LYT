module "cache"

test "writing and reading", ->
  cache.write "test", "string", "stringdata"
  cache.write "test", "obj",    { str: "value", arr: [1, 2, 3] }
  
  equal cache.read("test", "string"), "stringdata"
  deepEqual cache.read("test", "obj"), { str: "value", arr: [1, 2, 3] }

