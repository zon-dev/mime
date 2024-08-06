# mime
Support MIME (HTTP Media Types) types parse in Zig.


### Usage:
```zig
var mime = Mime.parse("text/plain; charset=utf-8; foo=bar");
try std.testing.expect(mime != null);
try std.testing.expect(std.mem.eql(u8, mime.?.essence, "text/plain; charset=utf-8; foo=bar"));
try std.testing.expect(std.mem.eql(u8, mime.?.basetype, "text"));
try std.testing.expect(std.mem.eql(u8, mime.?.subtype, "plain"));

const charset = mime.?.getParam("charset");
try testing.expectEqualStrings("utf-8", charset.?);

const foo = mime.?.getParam("foo");
try testing.expectEqualStrings("bar", foo.?);

const bar = mime.?.getParam("bar");
try testing.expect(bar == null);
```
