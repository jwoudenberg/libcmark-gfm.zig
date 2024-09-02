const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("cmark-gfm.h");
});

test "cmark_parse_document" {
    const md_str =
        \\# Hello, World!
        \\
        \\This is a paragraph.
        \\
        \\- item 1
        \\- item 2
        \\- item 3
        \\
        \\```zig
        \\fn main() !void {
        \\    const stdout = std.io.getStdOut().writer();
        \\    try stdout.print("Hello, World!\n", .{});
        \\}
        \\```
        \\
    ;

    const doc_node = c.cmark_parse_document(
        md_str.ptr,
        md_str.len,
        c.CMARK_OPT_DEFAULT,
    ) orelse return error.OutOfMemory;
    defer c.cmark_node_free(doc_node);

    const iter = c.cmark_iter_new(doc_node);
    defer c.cmark_iter_free(iter);

    var saw_node_types = std.StringHashMap(struct {}).init(testing.allocator);
    defer saw_node_types.deinit();

    var event = c.cmark_iter_next(iter);
    while (event != c.CMARK_EVENT_DONE) : (event = c.cmark_iter_next(iter)) {
        if (event != c.CMARK_EVENT_ENTER) continue;
        const node = c.cmark_iter_get_node(iter) orelse continue;
        const node_type = c.cmark_node_get_type_string(node);

        const node_type_str = std.mem.span(node_type);
        try saw_node_types.put(node_type_str, .{});
    }

    try testing.expect(saw_node_types.contains("document"));
    try testing.expect(saw_node_types.contains("heading"));
    try testing.expect(saw_node_types.contains("paragraph"));
    try testing.expect(saw_node_types.contains("list"));
    try testing.expect(saw_node_types.contains("item"));
    try testing.expect(saw_node_types.contains("code_block"));
}
