// //! Compute Mandelbrot Set in Zig.

const std = @import("std");
const Cx = std.math.Complex(f64);
const zigimg = @import("zigimg");

const IMAX = 100;
const RESOLUTION = [_]u64{ 1_000, 1_000 };
const topLeft = Cx{ .re = -2, .im = 1.2 };
const bottomRight = Cx{ .re = 0.6, .im = -1.2 };

test "complex" {
    const c1 = Cx.init(1.0, 0.0);
    const c2 = Cx.init(0.0, 1.0);
    const c3 = Cx.add(c1, c2);
    try std.testing.expectApproxEqRel(std.math.sqrt2, Cx.magnitude(c3), 1e-4);
    const c4 = Cx.mul(c1, c2);
    try std.testing.expectEqual(c4, c2);
}

fn Context(comptime T: type) type {
    return struct {
        resolution: [2]T,
        topLeft: Cx,
        bottomRight: Cx,
        imax: usize,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // const t0 = std.time.milliTimestamp();

    const ctx = Context(u64){ .resolution = RESOLUTION, .topLeft = topLeft, .bottomRight = bottomRight, .imax = IMAX };

    // const pixels = try createPlentyThreadsSlice(ctx, allocator);
    // const pixels = try createUnthreadedSlice(ctx, allocator);
    const pixels = try createBands(ctx, allocator);
    defer allocator.free(pixels);
    // const t1 = std.time.milliTimestamp();
    // print("Writing to PNG after: {}\n", .{t1 - t0});
    try writeToPNG("images/mandelbrot.png", pixels, RESOLUTION, allocator);
}

/// The Mandelbrot set is the set of complex numbers c for which the function `f(z) = z^2 + c` does not escape to infinity.
///
/// The function computes the number iterations for `z(n+1) = z(n)^2 + c` to escape.
///  It escapes when (norm > 4) or when it reaches max_iter.
///
/// Returns the number of iterations when escapes or null if it didn't escape
fn iterationNumber(c: Cx, imax: usize) ?usize {
    if (c.re > 0.6 or c.re < -2.1) return 0;
    if (c.im > 1.2 or c.im < -1.2) return 0;

    // first cardiod
    if ((c.re + 1) * (c.re + 1) + c.im * c.im < 0.0625) return null;

    var z = Cx{ .re = 0.0, .im = 0.0 };

    for (0..imax) |j| {
        if (sqnorm(z) > 4) return j;
        z = Cx.mul(z, z).add(c);
    }
    return null;
}

test "iter null when captured" {
    const c = Cx{ .re = 0.0, .im = 0.0 };
    const iter = iterationNumber(c, 30);
    try std.testing.expect(iter == null);
}
test "iter not null if escapes" {
    const c = Cx{ .re = 0.5, .im = 0.5 };
    const iter = iterationNumber(c, 30);
    try std.testing.expect(iter != null);
}

/// Creates an RGB arrays of u8 colour based on the number of iterations.
///
/// The colour if black when the point is captured.
///
/// The brighter the color the faster it escapes.
fn createRgb(iter: ?usize, imax: usize) [3]u8 {
    // If it didn't escape, return black
    if (iter == null) return [_]u8{ 0, 0, 0 };

    // Normalize time to [0,1] now that we know it isn't NULL
    const normalized = @as(f64, @floatFromInt(iter.?)) / @as(f64, @floatFromInt(imax));

    if (normalized < 0.5) {
        const scaled = normalized * 2;
        return [_]u8{ @as(u8, @intFromFloat(255 * (1 - scaled))), @as(u8, @intFromFloat(255 * (1 - scaled / 2))), @as(u8, @intFromFloat(127 + 128 * scaled)) };
    } else {
        const scaled = (normalized - 0.5) * 2.0;
        return [_]u8{ 0, @as(u8, @intFromFloat(127 * (1 - scaled / 2))), @as(u8, @intFromFloat(127 * (1 - scaled))) };
    }
}

test "createRgb" {
    const test_cases = [_]struct {
        iter: ?usize,
        expected: [3]u8,
    }{
        .{ .iter = null, .expected = [_]u8{ 0, 0, 0 } },
        .{ .iter = 0, .expected = [_]u8{ 255, 255, 127 } },
        .{ .iter = IMAX / 2, .expected = [_]u8{ 0, 127, 255 } },
        .{ .iter = IMAX, .expected = [_]u8{ 0, 63, 0 } },
    };

    for (test_cases) |tc| {
        const result = createRgb(tc.iter, IMAX);
        try std.testing.expectEqualSlices(u8, &tc.expected, &result);
    }
}

fn createRgb2(iter: ?usize, imax: usize) [3]u8 {
    // If it didn't escape, return black
    if (iter == null) return [_]u8{ 0, 0, 0 };

    if (iter.? < imax and iter.? > 0) {
        const i = iter.? / 16;
        return switch (i) {
            0 => [_]u8{ 66, 30, 15 },
            1 => [_]u8{ 25, 7, 26 },
            2 => [_]u8{ 9, 1, 47 },
            3 => [_]u8{ 4, 4, 73 },
            4 => [_]u8{ 0, 7, 100 },
            5 => [_]u8{ 12, 44, 138 },
            6 => [_]u8{ 24, 82, 177 },
            7 => [_]u8{ 57, 125, 209 },
            8 => [_]u8{ 134, 181, 229 },
            9 => [_]u8{ 211, 236, 248 },
            10 => [_]u8{ 241, 233, 191 },
            11 => [_]u8{ 248, 201, 95 },
            12 => [_]u8{ 255, 170, 0 },
            13 => [_]u8{ 204, 128, 0 },
            14 => [_]u8{ 153, 87, 0 },
            15 => [_]u8{ 106, 52, 3 },
            else => [_]u8{ 0, 0, 0 },
        };
    }
    return [_]u8{ 0, 0, 0 };
}

/// Given an image of size [width, height] pixels, and a region of
/// a complex plane defined by the topLeft and bottomRight,
/// the pixel coordinate in the output image is translated to a complex number
/// The pixel coordinate is the [row, column] of the image.
/// It returns the complex number that corresponds to the pixel coordinate.
/// but rotated.
fn mapPixel(pixel: [2]u64, ctx: Context(u64)) Cx {
    const w = ctx.bottomRight.re - ctx.topLeft.re;
    const h = ctx.bottomRight.im - ctx.topLeft.im;
    const px_width = ctx.resolution[0] - 1;
    const px_height = ctx.resolution[1] - 1;
    const scale_x = w / @as(f64, @floatFromInt(px_width));
    const scale_y = h / @as(f64, @floatFromInt(px_height));

    const re = ctx.topLeft.re + scale_x * @as(f64, @floatFromInt(pixel[1]));
    const im = ctx.topLeft.im + scale_y * @as(f64, @floatFromInt(pixel[0]));
    return Cx{ .re = re, .im = im };
}

test "mapPixel" {
    const test_tl = Cx{ .re = -2.1, .im = 1.2 };
    const test_br = Cx{ .re = 0.6, .im = -1.2 };
    const test_resolution = [_]u64{ 200, 100 };
    const ctx = .{ .resolution = test_resolution, .topLeft = test_tl, .bottomRight = test_br, .imax = 10 };

    const test_cases = [_]struct {
        pixel: [2]u64,
        expected: Cx,
    }{
        .{ .pixel = .{ 0, 0 }, .expected = test_tl },
        .{ .pixel = .{ 99, 199 }, .expected = test_br },
        .{ .pixel = .{ 99, 0 }, .expected = Cx{ .re = -2.1, .im = -1.2 } },
        .{ .pixel = .{ 0, 199 }, .expected = Cx{ .re = 0.6, .im = 1.2 } },
    };

    for (test_cases) |tc| {
        const result = mapPixel(tc.pixel, ctx);
        try std.testing.expectApproxEqRel(tc.expected.re, result.re, 1e-4);
        try std.testing.expectApproxEqRel(tc.expected.im, result.im, 1e-4);
    }
}

fn createBands(ctx: Context(u64), allocator: std.mem.Allocator) ![]u8 {
    const pixels = try allocator.alloc(u8, ctx.resolution[0] * ctx.resolution[1] * 3);
    errdefer allocator.free(pixels);

    const cpus = try std.Thread.getCpuCount();
    var threads = try allocator.alloc(std.Thread, cpus);
    defer allocator.free(threads);

    // half of the total rows
    const rows_to_process = ctx.resolution[1] / 2 + ctx.resolution[1] % 2;
    // one band is one count of cpus
    // const nb_rows_per_band = rows_to_process / cpus + rows_to_process % cpus;
    const rows_per_band = (rows_to_process + cpus - 1) / cpus;

    for (0..cpus) |cpu_count| {
        const start_row = cpu_count * rows_per_band;

        // Stop if there are no rows to process
        if (start_row >= rows_to_process) break;

        const end_row = @min(start_row + rows_per_band, rows_to_process);
        const args = .{ ctx, pixels, start_row, end_row };
        threads[cpu_count] = try std.Thread.spawn(.{}, processRows, args);
    }
    for (threads[0..cpus]) |thread| {
        thread.join();
    }

    return pixels;
}

fn processRows(ctx: Context(u64), pixels: []u8, start_row: usize, end_row: usize) void {
    for (start_row..end_row) |current_row| {
        processRow(ctx, pixels, current_row);
    }
}

fn processRow(ctx: Context(u64), pixels: []u8, row_id: usize) void {
    // Calculate the symmetric row
    const sym_row_id = ctx.resolution[1] - 1 - row_id;

    if (row_id <= sym_row_id) {
        // loop over columns
        for (0..ctx.resolution[0]) |col_id| {
            const c = mapPixel(.{ @as(u64, @intCast(row_id)), @as(u64, @intCast(col_id)) }, ctx);
            const iter = iterationNumber(c, ctx.imax);
            const colour = createRgb2(iter, ctx.imax);

            const p_idx = (row_id * ctx.resolution[0] + col_id) * 3;
            pixels[p_idx + 0] = colour[0];
            pixels[p_idx + 1] = colour[1];
            pixels[p_idx + 2] = colour[2];

            // Process the symmetric row (if it's different from current row)
            if (row_id != sym_row_id) {
                const sym_p_idx = (sym_row_id * ctx.resolution[0] + col_id) * 3;
                pixels[sym_p_idx + 0] = colour[0];
                pixels[sym_p_idx + 1] = colour[1];
                pixels[sym_p_idx + 2] = colour[2];
            }
        }
    }
}

fn writeToPNG(path: []const u8, pixels: []u8, resolution: [2]u64, allocator: std.mem.Allocator) !void {
    const w = resolution[0];
    const h = resolution[1];

    var image = try zigimg.Image.fromRawPixels(allocator, w, h, pixels, .rgb24);
    defer image.deinit();

    try image.writeToFilePath(path, .{ .png = .{} });
}

/// Compute the square of the norm of a complex number to avoid the square root
fn sqnorm(z: Cx) f64 {
    return z.re * z.re + z.im * z.im;
}

test "sqnorm" {
    const z = Cx{ .re = 2.0, .im = 2.0 };
    try std.testing.expectApproxEqRel(sqnorm(z), Cx.magnitude(z) * Cx.magnitude(z), 1e-4);
}

// fn createPlentyThreadsSlice(ctx: Context, allocator: std.mem.Allocator) ![]u8 {
//     const pixels = try allocator.alloc(u8, ctx.resolution[0] * ctx.resolution[1] * 3);
//     errdefer allocator.free(pixels);

//     const cpus = try std.Thread.getCpuCount();
//     var threads = try allocator.alloc(std.Thread, cpus);

//     defer allocator.free(threads);

//     const rows_to_process = ctx.resolution[1] / 2 + ctx.resolution[1] % 2;
//     var current_row: usize = 0;

//     while (current_row < rows_to_process) {
//         var spawned_threads: usize = 0;

//         // Spawn up to cpus threads or remaining rows, whichever is smaller
//         while (spawned_threads < cpus and current_row + spawned_threads < rows_to_process) {
//             const row = current_row + spawned_threads;

//             const args = .{ ctx, pixels, row };
//             threads[spawned_threads] = try std.Thread.spawn(.{}, processRow, args);
//             spawned_threads += 1;
//         }

//         // Wait for all spawned threads to complete
//         for (threads[0..spawned_threads]) |thread| {
//             thread.join();
//         }

//         current_row += spawned_threads;
//     }

//     return pixels;
// }

// fn createUnthreadedSlice(ctx: Context, allocator: std.mem.Allocator) ![]u8 {
//     var pixels = try allocator.alloc(u8, ctx.resolution[0] * ctx.resolution[1] * 3);
//     const rows_to_process = ctx.resolution[1] / 2 + ctx.resolution[1] % 2;
//     for (0..rows_to_process) |current_row| {
//         for (0..ctx.resolution[0]) |current_col| {
//             const c = mapPixel(.{ @as(u64, @intCast(current_col)), @as(u64, @intCast(current_row)) }, ctx);
//             const iter = iterationNumber(c);
//             const colour = createRgb(iter);
//             const pixel_index = (current_row * ctx.resolution[0] + current_col) * 3;
//             // copy RGB values to consecutive memory locations
//             pixels[pixel_index + 0] = colour[0]; //R
//             pixels[pixel_index + 1] = colour[1]; //G
//             pixels[pixel_index + 2] = colour[2]; //B

//             const mirror_y = ctx.resolution[1] - 1 - current_row;
//             if (mirror_y != current_row) {
//                 const mirror_pixel_index = (mirror_y * ctx.resolution[0] + current_col) * 3;
//                 pixels[mirror_pixel_index + 0] = colour[0]; //R
//                 pixels[mirror_pixel_index + 1] = colour[1]; //G
//                 pixels[mirror_pixel_index + 2] = colour[2]; //B
//             }
//         }
//     }
//     return pixels;
// }

// fn processUnsymmetrizeRow(ctx: Context, pixesl: []u8, y: usize) void {
//     for (0..ctx.resolution[0]) |x| {
//         const c = mapPixel(.{ @as(u32, @intCast(x)), @as(u32, @intCast(y)) }, ctx);
//         const iter = getIter(c);
//         const colour = createRgb(iter);

//         const p_idx = (y * ctx.resolution[0] + x) * 3;
//         pixesl[p_idx + 0] = colour[0];
//         pixesl[p_idx + 1] = colour[1];
//         pixesl[p_idx + 2] = colour[2];
//     }
// }
