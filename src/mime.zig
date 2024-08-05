const std = @import("std");
const HeaderIterator = std.http.HeaderIterator;

const testing = std.testing;

/// An IANA media type.
///
/// Read more: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
pub const Mime = struct {
    essence: []const u8,

    // The basetype represents the general category into which the data type falls, such as video or text.
    basetype: []const u8,

    // The subtype identifies the exact kind of data of the specified type the MIME type represents.
    // For example, for the MIME type text, the subtype might be plain (plain text),
    // html (HTML source code), or calendar (for iCalendar/.ics) files.
    subtype: []const u8,

    is_utf8: bool,

    // An optional parameter can be added to provide additional details:
    // type/subtype;parameter=value
    params: []Param,

    fn parse_param(param_string: []const u8) ?Param {
        // Find the equals sign (=) to split into key and value
        // const equals_index = p.indexOf('=');
        const equals_index = std.mem.indexOf(u8, param_string, "=");
        if (equals_index == null) {
            // std.debug.print("error: {s}\n", .{"Missing equal sign"});
            return null;
        }

        const equals_index_value = equals_index.?;
        if (equals_index_value == 0 or equals_index_value == param_string.len - 1) {
            // std.debug.print("error: {s}\n", .{"Invalid range"});
            return null;
        }

        const key = param_string[0..equals_index_value];
        var value = param_string[equals_index_value + 1 ..];
        value = std.mem.trimRight(u8, value, " \t");
        // Add the parsed parameter to the list
        if (!is_valid_param_key(key)) {
            // std.debug.print("error: {s}\n", .{"Invalid key"});
            return null;
        }
        if (!is_valid_param_value(value)) {
            // std.debug.print("error: {s}\n", .{"Invalid value"});
            return null;
        }

        return Param{ .key = key, .value = value };
    }

    // Function to parse parameters from a string
    fn parse_params(params_string: []const u8) ?[]Param {
        var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
        const allocator = gpa.allocator();
        var params = std.ArrayList(Param).init(allocator);

        // Split the input string by semicolons (;) to get individual parameters
        // var param_list = std.mem.splitSequence(u8, params_string, ";");
        // var param_list = std.mem.splitScalar(u8, params_string, ";");
        var param_list = std.mem.splitScalar(u8, params_string, ';');

        if (param_list.index == null) {
            const param_part = parse_param(params_string);
            if (param_part == null) {
                return null;
            }

            params.append(param_part.?) catch |err| {
                std.debug.print("error: {any}\n", .{err});
                return null;
            };
        }

        while (true) {
            const p = param_list.next();
            if (p == null) {
                break;
            }
            const param_part = parse_param(p.?);
            if (param_part == null) {
                 continue;
            }
            params.append(param_part.?) catch |err| {
                std.debug.print("error: {any}\n", .{err});
                continue;
            };
        }

        // return params.toOwnedSlice();
        if (params.items.len == 0) {
            return null;
        }

        return params.items;
    }
    fn is_valid_param_key(key: []const u8) bool {
        if (key.len == 0) return false;
        // Example validation: Ensure the key contains only printable ASCII characters
        for (key) |c| {
            if (!std.ascii.isPrint(c)) {
                return false;
            }
        }
        if (key[0] == ' ' or key[key.len - 1] == ' ') {
            return false;
        }
        return true;
    }

    // Function to validate parameter values
    fn is_valid_param_value(value: []const u8) bool {
        // Example validation: Ensure the value is non-empty
        if (value.len == 0) return false;

        // Example validation: Ensure the value contains only printable ASCII characters
        for (value) |c| {
            if (!std.ascii.isPrint(c)) {
                return false;
            }
        }
        if (value[0] == ' ' or value[value.len - 1] == ' ') {
            return false;
        }

        // Additional criteria can be added here based on application needs
        return true;
    }

    // Helper function to check if a part contains only valid characters
    fn is_valid_type(part: []const u8) bool {
        for (part) |c| {
            if (!std.ascii.isAlphanumeric(c) and c != '-') {
                return false;
            }
        }
        return true;
    }

    pub fn parse(mime_type: []const u8) ?Mime {

        // Must be at least "x/y" where x and y are non-empty
        if (mime_type.len < 3) {
            return null;
        }

        // const slash_index = mime_type.indexOf('/');
        const slash_index = std.mem.indexOf(u8, mime_type, "/");
        if (slash_index == null) return null; // Must contain '/'

        const type_part = mime_type[0..slash_index.?];
        var subtype_part = mime_type[slash_index.? + 1 ..];

        if (type_part.len == 0 or subtype_part.len == 0) return null; // Must have non-empty type and subtype

        // for (type_part) |c| if (!is_valid_type(c)) return null;
        if (!is_valid_type(type_part)) return null;

        const subtype_index = std.mem.indexOf(u8, subtype_part, ";");
        if (subtype_index == null) {
            // Remove any trailing HTTP whitespace from subtype.
            subtype_part = std.mem.trimRight(u8, subtype_part, " \t");
            // for (subtype_part) |c| if (!is_valid_type(c)) return null;
            if (!is_valid_type(subtype_part)) return null;

            return .{ .essence = mime_type, .basetype = type_part, .subtype = subtype_part, .is_utf8 = false, .params = &[_]Param{} };
        }

        var subtype = subtype_part[0..subtype_index.?];

        if (subtype.len == 0) return null; // Must have non-empty type and subtype

        // Remove any trailing HTTP whitespace from subtype.
        subtype = std.mem.trimRight(u8, subtype, " \t");
        // for (subtype) |c| if (!is_valid_type(c)) return null;
        if (!is_valid_type(subtype)) return null;

        // params should not be null
        var params_part = subtype_part[subtype_index.? + 1 ..];
        if (params_part.len == 0) return null;
        params_part = std.mem.trimLeft(u8, params_part, " \t");

        // Validate optional parameters
        const params = parse_params(params_part);
        if (params == null) return null;

        // return type_part.all(is_valid_char) and subtype_part.all(is_valid_char);
        return .{ .essence = mime_type, .basetype = type_part, .subtype = subtype, .is_utf8 = false, .params = params.? };
    }

    /// Create a new `Mime`.
    ///
    /// Follows the [WHATWG MIME parsing algorithm](https://mimesniff.spec.whatwg.org/#parsing-a-mime-type).
    pub fn init(s: []const u8) ?Mime {
        return parse(s);
    }

    pub fn fromExtension(extension: []const u8) ?Mime {
        switch (extension) {
            "html"[0..] => return HTML,
            "js"[0..] => return JAVASCRIPT,
            "mjs"[0..] => return JAVASCRIPT,
            "jsonp"[0..] => return JAVASCRIPT,
            "json"[0..] => return JSON,
            "css"[0..] => return CSS,
            "svg"[0..] => return SVG,
            "xml"[0..] => return XML,
            else => return null,
        }
    }

    /// Get a reference to a param.
    pub fn param(self: *Mime, name: []const u8) ?[]const u8 {
        for (self.params) |pair| {
            if (std.ascii.eqlIgnoreCase(pair.key, name)) {
                return pair.value;
            }
        }
        return null;
    }

    /// Remove a param from the set. Returns the `ParamValue` if it was contained within the set.
    pub fn removeParam(self: *Mime, key: []const u8) ?[]const u8 {
        if (std.ascii.eqlIgnoreCase(key, "charset") and self.is_utf8) {
            self.is_utf8 = false;
            return "utf-8";
        }

        var index: usize = 0;
        while (index < self.params.len) : (index += 1) {
            if (std.mem.eql(u8, self.params[index].key, key)) {
                return self.params[index].value;
            }
        }
        return null;
    }

    pub fn values(self: *Mime) !std.ArrayList(std.http.Header) {
        _ = self;
    }
};

const Param = struct {
    // name: ParamName,
    // value: ParamValue,
    key: []const u8,
    value: []const u8,
};

const HTML = Mime{
    .essence = "text/html",
    .basetype = "text",
    .subtype = "html",
    .is_utf8 = true,
    .params = &[_]Param{},
};

const JAVASCRIPT = Mime{
    .essence = "text/javascript",
    .basetype = "text",
    .subtype = "javascript",
    .is_utf8 = true,
    .params = &[_]Param{},
};

const JSON = Mime{
    .essence = "application/json",
    .basetype = "application",
    .subtype = "json",
    .is_utf8 = true,
    .params = &[_]Param{},
};

const CSS = Mime{
    .essence = "text/css",
    .basetype = "text",
    .subtype = "css",
    .is_utf8 = true,
    .params = &[_]Param{},
};

const SVG = Mime{
    .essence = "image/svg+xml",
    .basetype = "image",
    .subtype = "svg+xml",
    .is_utf8 = true,
    .params = &[_]Param{},
};

const XML = Mime{
    .essence = "application/xml",
    .basetype = "application",
    .subtype = "xml",
    .is_utf8 = true,
    .params = &[_]Param{},
};

test "Valid mime type" {
    // See more at https://mimesniff.spec.whatwg.org/#example-valid-mime-type-string
    const valid_case = [_][]const u8{
        "text/html",
        // text_plain_uppercase
        "TEXT/PLAIN",
        // text_plain_charset_utf8
        "text/plain; charset=utf-8",
        // text_plain_charset_utf8_uppercase
        "TEXT/PLAIN; CHARSET=UTF-8",
        // text_plain_charset_utf8_quoted
        "text/plain; charset=\"utf-8\"",
        // charset_utf8_extra_spaces
        "text/plain  ;  charset=utf-8  ;  foo=bar",
        // text_plain_charset_utf8_extra
        "text/plain; charset=utf-8; foo=bar",
        // text_plain_charset_utf8_extra_uppercase
        "TEXT/PLAIN; CHARSET=UTF-8; FOO=BAR",
        // subtype_space_before_params
        "text/plain ; charset=utf-8",
        // params_space_before_semi
        "text/plain; charset=utf-8 ; foo=bar",
    };
    for (valid_case) |s| {
        const mime_type = Mime.parse(s);
        try testing.expect(mime_type != null);
    }
}

test "Invalid mime type" {
    // See more at https://mimesniff.spec.whatwg.org/#example-valid-mime-type-string
    const invalid_case = [_][]const u8{
        // empty
        "",
        // slash_only
        "/",
        // slash_only_space
        " / ",
        // slash_only_space_before_params
        " / foo=bar",
        // slash_only_space_after_params
        "/html; charset=utf-8",
        "text/html;",
        // error_type_spaces
        "te xt/plain",
        // error_type_lf
        "te\nxt/plain",
        // error_type_cr
        "te\rxt/plain",
        // error_subtype_spaces
        "text/plai n",
        // error_subtype_crlf
        "text/\r\nplain",
        // error_param_name_crlf,
        "text/plain;\r\ncharset=utf-8",
        // error_param_value_quoted_crlf
        "text/plain;charset=\"\r\nutf-8\"",
        // error_param_space_before_equals
        "text/plain; charset =utf-8",
        // error_param_space_after_equals
        "text/plain; charset= utf-8",
    };

    for (invalid_case, 0..) |invalid_s, i| {
        const invalid_type = Mime.parse(invalid_s);
        if (invalid_type != null) {
            std.debug.print("invalid_index: {} essence {s} ,basetype: {s}, subtype:{s}, params:{any} \n", .{ i, invalid_type.?.essence, invalid_type.?.basetype, invalid_type.?.subtype, invalid_type.?.params });
        }

        try testing.expect(invalid_type == null);
    }
}

test "parse params" {
    var mime = Mime.parse("text/plain; charset=utf-8; foo=bar");
    try testing.expect(mime != null);

    const charset = mime.?.param("charset");
    try testing.expectEqualStrings("utf-8", charset.?);

    // TODO: Add more tests
    // const foo = mime.?.param("foo");
    // try testing.expect(foo != null);
    // try testing.expectEqualStrings("bar", foo.?);
    // const bar = mime.?.param("bar");
    // try testing.expect(bar == null);
}

const ParseError = error{
    MissingSlash,
    MissingEqual,
    MissingQuote,
    InvalidToken,
    InvalidRange,
    TooLong,
};

// fn formatParseError(e: ParseError, writer: *std.io.AnyWriter) !void {
//     const description = switch (e) {
//         ParseError.MissingSlash => "a slash (/) was missing between the type and subtype",
//         ParseError.MissingEqual => "an equals sign (=) was missing between a parameter and its value",
//         ParseError.MissingQuote => "a quote (\") was missing from a parameter value",
//         ParseError.InvalidToken => "invalid token",
//         ParseError.InvalidRange => "unexpected asterisk",
//         ParseError.TooLong => "the string is too long",
//     };
// }
