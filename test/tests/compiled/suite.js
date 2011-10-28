(function() {
  module("cache");
  test("writing and reading", function() {
    cache.write("test", "string", "stringdata");
    cache.write("test", "obj", {
      str: "value",
      arr: [1, 2, 3]
    });
    equal(cache.read("test", "string"), "stringdata");
    return deepEqual(cache.read("test", "obj"), {
      str: "value",
      arr: [1, 2, 3]
    });
  });
  module("NCCFile class");
  test("Basics", function() {
    var file;
    file = new NCCFile("fixtures/ncc.html");
    equal(file.creators(), "Richard G. Lipsey, Paul N. Courant, Douglas D. Purvis & Peter O. Steiner");
    equal(file.metadata.totalTime.content, "91:27:21");
    return equal(file.structure.length, 6);
  });
  module("rpc");
  test("should raise on non-string rpc names", function() {
    raises(function() {
      return rpc(false);
    });
    raises(function() {
      return rpc(23);
    });
    raises(function() {
      return rpc({});
    });
    return raises(function() {
      return rpc([]);
    });
  });
  module("rpc/XML conversion");
  test("basics", function() {
    equal(rpc.toXML({
      someKey: "some value"
    }), "<ns1:someKey>some value</ns1:someKey>");
    return equal(rpc.toXML({
      noValue: null
    }), "<ns1:noValue></ns1:noValue>");
  });
  test("character escapes", function() {
    equal(rpc.toXML("special chars & < >"), "special chars &amp; &lt; &gt;");
    return equal(rpc.toXML("special chars &amp; &lt; &gt;"), "special chars &amp; &lt; &gt;");
  });
  test("nesting", function() {
    return equal(rpc.toXML({
      x: {
        y: {
          z: 23
        }
      }
    }), "<ns1:x><ns1:y><ns1:z>23</ns1:z></ns1:y></ns1:x>");
  });
  test("arrays", function() {
    return equal(rpc.toXML({
      x: [1, 2, 3]
    }), "<ns1:x>1</ns1:x><ns1:x>2</ns1:x><ns1:x>3</ns1:x>");
  });
  test("all together now!", function() {
    var input;
    input = {
      x: {
        y: "something & something > &amp; but < something big",
        z: [1, 2, 3]
      }
    };
    return equal(rpc.toXML(input), "<ns1:x><ns1:y>something &amp; something &gt; &amp; but &lt; something big</ns1:y><ns1:z>1</ns1:z><ns1:z>2</ns1:z><ns1:z>3</ns1:z></ns1:x>");
  });
  module("utils/time");
  test("parseTime", function() {
    equal(parseTime(false), 0, "Shold return 0 on bad input");
    equal(parseTime("monkey!"), 0, "Shold return 0 on bad input");
    equal(parseTime("00:01"), 1);
    equal(parseTime("00:00:01"), 1);
    equal(parseTime("01:00"), 60);
    equal(parseTime("00:01:00"), 60);
    equal(parseTime("1:00:00"), 3600);
    return equal(parseTime("1:02:03"), 3723);
  });
  test("formatTime", function() {
    equal(formatTime(0), "0:00:00");
    equal(formatTime(-31), "0:00:00");
    equal(formatTime(1), "0:00:01");
    equal(formatTime(60), "0:01:00");
    equal(formatTime(3600), "1:00:00");
    equal(formatTime(3723), "1:02:03");
    return equal(formatTime(39723), "11:02:03");
  });
}).call(this);
