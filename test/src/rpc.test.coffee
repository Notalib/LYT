module "rpc"

test "should raise on non-string rpc names", ->
  raises -> LYT.rpc false
  raises -> LYT.rpc 23
  raises -> LYT.rpc {}
  raises -> LYT.rpc []

# =============

module "rpc/XML conversion"

test "basics", ->
  equal LYT.rpc.toXML({someKey: "some value"}), "<ns1:someKey>some value</ns1:someKey>"
  equal LYT.rpc.toXML({noValue: null}), "<ns1:noValue></ns1:noValue>"

test "character escapes", ->
  equal LYT.rpc.toXML("special chars & < >"), "special chars &amp; &lt; &gt;"
  equal LYT.rpc.toXML("special chars &amp; &lt; &gt;"), "special chars &amp;amp; &amp;lt; &amp;gt;"

test "nesting", ->
  equal LYT.rpc.toXML({x: {y: {z: 23}}}), "<ns1:x><ns1:y><ns1:z>23</ns1:z></ns1:y></ns1:x>"

test "arrays", ->
  equal LYT.rpc.toXML({x: [1, 2, 3]}), "<ns1:x>1</ns1:x><ns1:x>2</ns1:x><ns1:x>3</ns1:x>"

test "all together now!", ->
  input = 
    x:
      y: "something & something > &amp; but < something big",
      z: [1, 2, 3]
  equal LYT.rpc.toXML(input), "<ns1:x><ns1:y>something &amp; something &gt; &amp;amp; but &lt; something big</ns1:y><ns1:z>1</ns1:z><ns1:z>2</ns1:z><ns1:z>3</ns1:z></ns1:x>"

  