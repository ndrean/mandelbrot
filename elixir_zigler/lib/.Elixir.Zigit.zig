const beam = @import("beam");
const std = @import("std");
const Cx = std.math.Complex(f64);

const IMAX = 100;
const topLeft = Cx{ .re = -2.0, .im = 1.2 };
const bottomRight = Cx{ .re = 0.6, .im = -1.2 };
const w = bottomRight.re - topLeft.re;
const h = topLeft.im - bottomRight.im;

/// nif: generate_mandelbrot/2 Threaded
pub fn generate_mandelbrot(res_x: usize, res_y: usize, sym: bool) !beam.term {
    const pixels = try beam.allocator.alloc(u8, res_x * res_y * 3);
    defer beam.allocator.free(pixels);

    // const res = try createUnthreadedSlice(pixels, res_x, res_y);
    const res = try createBands(pixels, res_x, res_y, sym);
    return beam.make(res, .{ .as = .binary });
    // return beam.make(res, .{});
}

fn createBands(pixels: []u8, res_x: usize, res_y: usize, sym: bool) ![]u8 {
    // const pixels = try allocator.alloc(u8, ctx.resolution[0] * ctx.resolution[1] * 3);
    // errdefer allocator.free(pixels);

    const cpus = try std.Thread.getCpuCount();
    var threads = try beam.allocator.alloc(std.Thread, cpus);
    defer beam.allocator.free(threads);

    // half of the total rows if sym true
    var rows_to_process: usize = res_x;
    if (sym) rows_to_process = res_x / 2 + res_x % 2;

    // one band is one count of cpus
    const nb_rows_per_band = rows_to_process / cpus + rows_to_process % cpus;
    std.debug.print("nb_rows_per_band: {}\n", .{nb_rows_per_band});

    for (0..cpus) |cpu_count| {
        const start_row = cpu_count * nb_rows_per_band;
        const end_row = start_row + nb_rows_per_band;
        const args = .{ res_x, res_y, pixels, start_row, end_row };
        threads[cpu_count] = try std.Thread.spawn(.{}, processRows, args);
    }
    for (threads[0..cpus]) |thread| {
        thread.join();
    }

    return pixels;
}

fn processRow(res_x: usize, res_y: usize, pixels: []u8, row_id: usize) void {
    // Calculate the symmetric row
    const sym_row_id = res_x - 1 - row_id;

    if (row_id <= sym_row_id) {
        // loop over columns
        for (0..res_y) |col_id| {
            const c = pixelToComplex(.{ @as(usize, @intCast(col_id)), @as(usize, @intCast(row_id)) }, res_x, res_y);
            const iter = getIter(c);
            const colour = createRgb(iter);

            const p_idx = (row_id * res_y + col_id) * 3;
            pixels[p_idx + 0] = colour[0];
            pixels[p_idx + 1] = colour[1];
            pixels[p_idx + 2] = colour[2];

            // Process the symmetric row (if it's different from current row)
            if (row_id != sym_row_id) {
                const sym_p_idx = (sym_row_id * res_y + col_id) * 3;
                pixels[sym_p_idx + 0] = colour[0];
                pixels[sym_p_idx + 1] = colour[1];
                pixels[sym_p_idx + 2] = colour[2];
            }
        }
    }
}

fn processRows(res_x: usize, res_y: usize, pixels: []u8, start_row: usize, end_row: usize) void {
    for (start_row..end_row) |current_row| {
        processRow(res_x, res_y, pixels, current_row);
    }
}

fn createUnthreadedSlice(pixels: []u8, res_x: usize, res_y: usize) ![]u8 {
    const rows_to_process = res_x / 2 + res_x % 2;
    for (0..rows_to_process) |current_row| {
        for (0..res_y) |current_col| {
            const c = pixelToComplex(.{ @as(u32, @intCast(current_col)), @as(u32, @intCast(current_row)) }, res_x, res_y);
            const iter = getIter(c);
            const colour = createRgb(iter);
            const pixel_index = (current_row * res_y + current_col) * 3;
            // copy RGB values to consecutive memory locations
            pixels[pixel_index + 0] = colour[0]; //R
            pixels[pixel_index + 1] = colour[1]; //G
            pixels[pixel_index + 2] = colour[2]; //B

            const mirror_y = res_x - 1 - current_row;
            if (mirror_y != current_row) {
                const mirror_pixel_index = (mirror_y * res_y + current_col) * 3;
                pixels[mirror_pixel_index + 0] = colour[0]; //R
                pixels[mirror_pixel_index + 1] = colour[1]; //G
                pixels[mirror_pixel_index + 2] = colour[2]; //B
            }
        }
    }
    //return beam.make(pixels, .{});
    return pixels;
}

fn pixelToComplex(pix: [2]usize, res_x: usize, res_y: usize) Cx {
    const re = @as(f64, @floatFromInt(pix[0])) / @as(f64, @floatFromInt(res_x)) * w;
    const im = @as(f64, @floatFromInt(pix[1])) / @as(f64, @floatFromInt(res_y)) * h;
    return Cx{ .re = (topLeft.re + re) * w, .im = (topLeft.im - im) * h };
}

fn getIter(c: Cx) ?usize {
    if (c.re > 0.6 or c.re < -2.1) return null;
    if (c.im > 1.2 or c.im < -1.2) return null;

    var z = Cx{ .re = 0.0, .im = 0.0 };

    for (0..IMAX) |j| {
        if (sqnorm(z) > 4) return j;
        z = Cx.mul(z, z).add(c);
    }
    return null;
}

fn sqnorm(z: Cx) f64 {
    return z.re * z.re + z.im * z.im;
}

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
