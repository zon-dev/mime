# mime
Support MIME (HTTP Media Types) as strong types in Zig.


### Usage:
```zig
var mime = Mime.parse("text/plain; charset=utf-8; foo=bar");
try testing.expect(mime != null);

const charset = mime.?.getParam("charset");
try testing.expectEqualStrings("utf-8", charset.?);

const foo = mime.?.getParam("foo");
try testing.expectEqualStrings("bar", foo.?);

const bar = mime.?.getParam("bar");
try testing.expect(bar == null);
```
