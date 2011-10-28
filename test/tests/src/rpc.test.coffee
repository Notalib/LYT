module "rpc"

test "should raise on non-string rpc names", ->
  raises -> rpc false
  raises -> rpc 23
  raises -> rpc {}
  raises -> rpc []

# =============

module "rpc/XML conversion"

test "basics", ->
  equal rpc.toXML({someKey: "some value"}), "<ns1:someKey>some value</ns1:someKey>"
  equal rpc.toXML({noValue: null}), "<ns1:noValue></ns1:noValue>"

test "character escapes", ->
  equal rpc.toXML("special chars & < >"), "special chars &amp; &lt; &gt;"
  equal rpc.toXML("special chars &amp; &lt; &gt;"), "special chars &amp; &lt; &gt;"

test "nesting", ->
  equal rpc.toXML({x: {y: {z: 23}}}), "<ns1:x><ns1:y><ns1:z>23</ns1:z></ns1:y></ns1:x>"

test "arrays", ->
  equal rpc.toXML({x: [1, 2, 3]}), "<ns1:x>1</ns1:x><ns1:x>2</ns1:x><ns1:x>3</ns1:x>"

test "all together now!", ->
  input = 
    x:
      y: "something & something > &amp; but < something big",
      z: [1, 2, 3]
  equal rpc.toXML(input), "<ns1:x><ns1:y>something &amp; something &gt; &amp; but &lt; something big</ns1:y><ns1:z>1</ns1:z><ns1:z>2</ns1:z><ns1:z>3</ns1:z></ns1:x>"

  