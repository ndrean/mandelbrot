// //! Compute Mandelbrot Set in Zig.

const std = @import("std");
const Cx = std.math.Complex(f64);
const zigimg = @import("zigimg");

const print = std.debug.print;

const IMAX: usize = 100;
const RESOLUTION = [_]u64{ 30_000, 30_000 };

test "complex" {
    const c1 = Cx.init(1.0, 0.0);
    const c2 = Cx.init(0.0, 1.0);
    const c3 = Cx.add(c1, c2);
    try std.testing.expectApproxEqRel(std.math.sqrt2, Cx.magnitude(c3), 1e-4);
    const c4 = Cx.mul(c1, c2);
    try std.testing.expectEqual(c4, c2);
}
/// Compute the square of the norm of a complex number to avoid the square root
fn sqnorm(z: Cx) f64 {
    return z.re * z.re + z.im * z.im;
}

test "sqnorm" {
    const z = Cx{ .re = 2.0, .im = 2.0 };
    try std.testing.expectApproxEqRel(sqnorm(z), Cx.magnitude(z) * Cx.magnitude(z), 1e-4);
}

/// The Mandelbrot set is the set of complex numbers c for which the function `f(z) = z^2 + c` does not escape to infinity.
///
/// The function computes the number iterations for `z(n+1) = z(n)^2 + c` to escape.
///  It escapes when (norm > 4) or when it reaches max_iter.
///
/// Returns the number of iterations when escapes or null if it didn't escape
fn iterationNumber(c: Cx) ?usize {
    if (c.re > 0.6 or c.re < -2.1) return null;
    if (c.im > 1.2 or c.im < -1.2) return null;
    // first cardiod
    if ((c.re + 1) * (c.re + 1) + c.im * c.im < 0.0625) return null;

    var z = Cx{ .re = 0.0, .im = 0.0 };

    for (0..IMAX) |j| {
        if (sqnorm(z) > 4) return j;
        z = Cx.mul(z, z).add(c);
    }
    return null;
}

test "iter when captured" {
    const c = Cx{ .re = 0.0, .im = 0.0 };
    const iter = iterationNumber(c);
    try std.testing.expect(iter == null);
}
test "iter if escapes" {
    const c = Cx{ .re = 1.0, .im = 1.0 };
    const iter = iterationNumber(c);
    try std.testing.expect(iter != null);
}

/// Creates an RGB arrays of u8 colour based on the number of iterations.
///
/// The colour if black when the point is captured.
///
/// The brighter the color the faster it escapes.
fn createRgb(iter: ?usize) [3]u8 {
    // If it didn't escape, return black
    if (iter == null) return [_]u8{ 0, 0, 0 };

    // Normalize time to [0,1] now that we know it escaped
    const normalized = @as(f64, @floatFromInt(iter.?)) / @as(f64, @floatFromInt(IMAX));

    if (normalized < 0.5) {
        const scaled = normalized * 2;
        return [_]u8{ @as(u8, @intFromFloat(255.0 * (1.0 - scaled))), @as(u8, @intFromFloat(255.0 * (1.0 - scaled / 2))), @as(u8, @intFromFloat(127 + 128 * scaled)) };
    } else {
        const scaled = (normalized - 0.5) * 2.0;
        return [_]u8{ 0, @as(u8, @intFromFloat(127 * (1 - scaled))), @as(u8, @intFromFloat(255.0 * (1.0 - scaled))) };
    }
}

test "createRgb" {
    const iter1 = 0;
    const expected1 = [_]u8{ 255, 255, 127 };
    var result = createRgb(iter1);
    try std.testing.expectEqualSlices(u8, &expected1, &result);

    const iter2 = IMAX / 2;
    const expected2 = [_]u8{ 0, 127, 255 };
    result = createRgb(iter2);
    try std.testing.expectEqualSlices(u8, &expected2, &result);

    const iter3 = IMAX;
    const expected3 = [_]u8{ 0, 0, 0 };
    result = createRgb(iter3);
    try std.testing.expectEqualSlices(u8, &expected3, &result);
}

const Context = struct {
    resolution: [2]u64,
    topLeft: Cx,
    bottomRight: Cx,
};

/// Given an image of size img,
/// a complex plane defined by the topLeft and bottomRight,
/// the pixel coordinate in the output image is translated to a complex number
///
/// Example: With an image of size img=100x200, the point/pixel at 75,175,
/// should map to 0.5 + 0.5i
fn pixelToComplex(pix: [2]u64, ctx: Context) Cx {
    const w = ctx.bottomRight.re - ctx.topLeft.re;
    const h = -ctx.topLeft.im + ctx.bottomRight.im;
    const scale_x = w / @as(f64, @floatFromInt(ctx.resolution[0] - 1));
    const scale_y = h / @as(f64, @floatFromInt(ctx.resolution[1] - 1));

    const re = ctx.topLeft.re + scale_x * @as(f64, @floatFromInt(pix[0]));
    const im = ctx.topLeft.im + scale_y * @as(f64, @floatFromInt(pix[1]));
    return Cx{ .re = re, .im = im };

    // const re = @as(f64, @floatFromInt(pix[0])) / @as(f64, @floatFromInt(ctx.resolution[0])) * w;
    // const im = @as(f64, @floatFromInt(pix[1])) / @as(f64, @floatFromInt(ctx.resolution[1])) * h;
}

// test "pixelToComplex" {
//     const test_cases = [_]struct {
//         pix: [2]u32,
//         expected: Cx,
//     }{
//         .{ .pix = .{ 0, 0 }, .expected = Cx{ .re = -2, .im = 1.2 } },
//         .{ .pix = .{ 100, 200 }, .expected = Cx{ .re = 0.8, .im = -1.2 } },
//         .{ .pix = .{ 50, 100 }, .expected = Cx{ .re = -0.6, .im = 0.0 } },
//     };

//     const ctx = .{ .resolution = RESOLUTION, .topLeft = Cx{ .re = -2, .im = 1.2 }, .bottomRight = Cx{ .re = 0.8, .im = -1.2 } };

//     for (test_cases) |tc| {
//         const result = pixelToComplex(tc.pix, ctx);
//         try std.testing.expectApproxEqRel(tc.expected.re, result.re, 1e-6);
//         try std.testing.expectApproxEqRel(tc.expected.im, result.im, 1e-6);
//     }

//     const topLeft = Cx{ .re = -1, .im = 1 };
//     const bottomRight = Cx{ .re = 1, .im = -1 };
//     const ctx = Context{ .resolution = .{ 100, 200 }, .topLeft = topLeft, .bottomRight = bottomRight };
//     const pix = .{ 75, 150 };
//     const expected = Cx{ .re = 0.5, .im = -0.5 };
//     const result = pixelToComplex(pix, ctx);
//     try std.testing.expect(expected.re == result.re and expected.im == result.im);
// }

fn createUnthreadedSlice(ctx: Context, allocator: std.mem.Allocator) ![]u8 {
    var pixels = try allocator.alloc(u8, ctx.resolution[0] * ctx.resolution[1] * 3);
    const rows_to_process = ctx.resolution[1] / 2 + ctx.resolution[1] % 2;
    for (0..rows_to_process) |current_row| {
        for (0..ctx.resolution[0]) |current_col| {
            const c = pixelToComplex(.{ @as(u64, @intCast(current_col)), @as(u64, @intCast(current_row)) }, ctx);
            const iter = iterationNumber(c);
            const colour = createRgb(iter);
            const pixel_index = (current_row * ctx.resolution[0] + current_col) * 3;
            // copy RGB values to consecutive memory locations
            pixels[pixel_index + 0] = colour[0]; //R
            pixels[pixel_index + 1] = colour[1]; //G
            pixels[pixel_index + 2] = colour[2]; //B

            const mirror_y = ctx.resolution[1] - 1 - current_row;
            if (mirror_y != current_row) {
                const mirror_pixel_index = (mirror_y * ctx.resolution[0] + current_col) * 3;
                pixels[mirror_pixel_index + 0] = colour[0]; //R
                pixels[mirror_pixel_index + 1] = colour[1]; //G
                pixels[mirror_pixel_index + 2] = colour[2]; //B
            }
        }
    }
    return pixels;
}

// fn processUnsymmetrizeRow(ctx: Context, pixesl: []u8, y: usize) void {
//     for (0..ctx.resolution[0]) |x| {
//         const c = pixelToComplex(.{ @as(u32, @intCast(x)), @as(u32, @intCast(y)) }, ctx);
//         const iter = getIter(c);
//         const colour = createRgb(iter);

//         const p_idx = (y * ctx.resolution[0] + x) * 3;
//         pixesl[p_idx + 0] = colour[0];
//         pixesl[p_idx + 1] = colour[1];
//         pixesl[p_idx + 2] = colour[2];
//     }
// }

fn processRow(ctx: Context, pixels: []u8, row_id: usize) void {
    // Calculate the symmetric row
    const sym_row_id = ctx.resolution[1] - 1 - row_id;

    if (row_id <= sym_row_id) {
        // loop over columns
        for (0..ctx.resolution[1]) |col_id| {
            const c = pixelToComplex(.{ @as(u64, @intCast(col_id)), @as(u64, @intCast(row_id)) }, ctx);
            const iter = iterationNumber(c);
            const colour = createRgb(iter);

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

fn processRows(ctx: Context, pixels: []u8, start_row: usize, end_row: usize) void {
    for (start_row..end_row) |current_row| {
        processRow(ctx, pixels, current_row);
    }
}

fn createBands(ctx: Context, allocator: std.mem.Allocator) ![]u8 {
    const pixels = try allocator.alloc(u8, ctx.resolution[0] * ctx.resolution[1] * 3);
    errdefer allocator.free(pixels);

    const cpus = try std.Thread.getCpuCount();
    var threads = try allocator.alloc(std.Thread, cpus);
    defer allocator.free(threads);

    // half of the total rows
    const rows_to_process = ctx.resolution[1] / 2 + ctx.resolution[1] % 2;
    // one band is one count of cpus
    const nb_rows_per_band = rows_to_process / cpus + rows_to_process % cpus;
    print("nb_rows_per_band: {}\n", .{nb_rows_per_band});

    for (0..cpus) |cpu_count| {
        const start_row = cpu_count * nb_rows_per_band;
        const end_row = start_row + nb_rows_per_band;
        const args = .{ ctx, pixels, start_row, end_row };
        threads[cpu_count] = try std.Thread.spawn(.{}, processRows, args);
    }
    for (threads[0..cpus]) |thread| {
        thread.join();
    }

    return pixels;
}

//

// test "createSlice" {
//     _ = try createSlice(.{ 100, 200 }, Cx{ .re = -1, .im = 1 }, Cx{ .re = 1, .im = -1 }, std.testing.allocator);
// }

fn writeToPNG(path: []const u8, pixels: []u8, resolution: [2]u64, allocator: std.mem.Allocator) !void {
    const w = resolution[0];
    const h = resolution[1];

    var image = try zigimg.Image.fromRawPixels(allocator, w, h, pixels, .rgb24);
    defer image.deinit();

    try image.writeToFilePath(path, .{ .png = .{} });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const t0 = std.time.milliTimestamp();
    const ctx = .{ .resolution = RESOLUTION, .topLeft = Cx{ .re = -2, .im = 1.2 }, .bottomRight = Cx{ .re = 0.8, .im = -1.2 } };

    // const pixels = try createPlentyThreadsSlice(ctx, allocator);
    // const pixels = try createUnthreadedSlice(ctx, allocator);
    const pixels = try createBands(ctx, allocator);
    defer allocator.free(pixels);
    const t1 = std.time.milliTimestamp();
    print("Writing to PNG after: {}\n", .{t1 - t0});
    try writeToPNG("mandelbrotband.png", pixels, RESOLUTION, allocator);
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
