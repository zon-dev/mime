const std = @import("std");

const method = std.http.Method;
/// The `MediaType` enum represents the type of a media content.
///
/// See more at https://www.iana.org/assignments/media-types/media-types.xhtml
const MediaType = enum {
    TEXT_PLAIN,
    TEXT_PLAIN_UTF_8,
    TEXT_HTML,
    TEXT_HTML_UTF_8,
    TEXT_CSS,
    TEXT_CSS_UTF_8,
    TEXT_JAVASCRIPT,
    TEXT_XML,
    TEXT_EVENT_STREAM,
    TEXT_CSV,
    TEXT_CSV_UTF_8,
    TEXT_TAB_SEPARATED_VALUES,
    TEXT_TAB_SEPARATED_VALUES_UTF_8,
    TEXT_VCARD,
    IMAGE_JPEG,
    IMAGE_GIF,
    IMAGE_PNG,
    IMAGE_BMP,
    IMAGE_SVG,
    FONT_WOFF,
    FONT_WOFF2,
    APPLICATION_JSON,
    APPLICATION_JAVASCRIPT,
    APPLICATION_JAVASCRIPT_UTF_8,
    APPLICATION_WWW_FORM_URLENCODED,
    APPLICATION_OCTET_STREAM,
    APPLICATION_MSGPACK,
    APPLICATION_PDF,
    APPLICATION_DNS,

    /// From [RFC6838](http://tools.ietf.org/html/rfc6838#section-4.2):
    ///
    /// All registered media types MUST be assigned top-level type and
    /// subtype names.  The combination of these names serves to uniquely
    /// identify the media type, and the subtype name facet (or the absence
    /// of one) identifies the registration tree.  Both top-level type and
    /// subtype names are case-insensitive.
    ///
    /// Type and subtype names MUST conform to the following ABNF:
    ///
    ///     type-name = restricted-name
    ///     subtype-name = restricted-name
    ///
    ///     restricted-name = restricted-name-first *126restricted-name-chars
    ///     restricted-name-first  = ALPHA / DIGIT
    ///     restricted-name-chars  = ALPHA / DIGIT / "!" / "#" /
    ///                              "$" / "&" / "-" / "^" / "_"
    ///     restricted-name-chars =/ "." ; Characters before first dot always
    ///                                  ; specify a facet name
    ///     restricted-name-chars =/ "+" ; Characters after last plus always
    ///                                  ; specify a structured syntax suffix
    /// See more at [HTTP](https://tools.ietf.org/html/rfc7231#section-3.1.1.1):
    //
    ///     media-type = type "/" subtype *( OWS ";" OWS parameter )
    ///     type       = token
    ///     subtype    = token
    ///     parameter  = token "=" ( token / quoted-string )
    ///
    // pub fn parse(s: []const u8) !Mime {}

    pub fn phrase(self: MediaType) ?[]const u8 {
        return switch (self) {
            .TEXT_PLAIN => return "text/plain",
            .TEXT_PLAIN_UTF_8 => return "text/plain; charset=utf-8",
            .TEXT_HTML => return "text/html",
            .TEXT_HTML_UTF_8 => return "text/html; charset=utf-8",
            .TEXT_CSS => return "text/css",
            .TEXT_CSS_UTF_8 => return "text/css; charset=utf-8",
            .TEXT_JAVASCRIPT => return "text/javascript",
            .TEXT_XML => return "text/xml",
            .TEXT_EVENT_STREAM => return "text/event-stream",
            .TEXT_CSV => return "text/csv",
            .TEXT_CSV_UTF_8 => return "text/csv, charset=utf-8",
            .TEXT_TAB_SEPARATED_VALUES => return "text/tab-separated-values",
            .TEXT_TAB_SEPARATED_VALUES_UTF_8 => return "text/tab-separated-values, charset=utf-8",
            .TEXT_VCARD => return "text/vcard",
            .IMAGE_JPEG => return "image/jpeg",
            .IMAGE_GIF => return "image/gif",
            .IMAGE_PNG => return "image/png",
            .IMAGE_BMP => return "image/bmp",
            .IMAGE_SVG => return "image/svg+xml",
            .FONT_WOFF => return "font/woff",
            .FONT_WOFF2 => return "font/woff2",
            .APPLICATION_JSON => return "application/json",
            .APPLICATION_JAVASCRIPT => return "application/javascript",
            .APPLICATION_JAVASCRIPT_UTF_8 => return "application/javascript, charset=utf-8",
            .APPLICATION_WWW_FORM_URLENCODED => return "application/x-www-form-urlencoded",
            .APPLICATION_OCTET_STREAM => return "application/octet-stream",
            .APPLICATION_MSGPACK => return "application/msgpack",
            .APPLICATION_PDF => return "application/pdf",
            .APPLICATION_DNS => return "application/dns-message",
            else => return null,
        };
    }

    test {
        try std.testing.expectEqualStrings("text/plain", MediaType.TEXT_PLAIN.phrase().?);
        try std.testing.expectEqualStrings("text/css; charset=utf-8", MediaType.TEXT_CSS_UTF_8.phrase().?);
        try std.testing.expectEqualStrings("application/json", MediaType.APPLICATION_JSON.phrase().?);
    }
};
