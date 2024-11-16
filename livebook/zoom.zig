const beam = @import("beam");
const std = @import("std");

const print = std.debug.print;

const Point = struct { x: f32, y: f32 };
const point_size: usize = @sizeOf(Point);
// print("Check Point size: {}", .{point_size});

// / nif: generate_view
pub fn generate_view(data: [*]const u8, len: u32, imax: usize) !void {
    if (len < @sizeOf(Point)) {
        return error.BufferTooSmall;
    }

    // Ensure the length is a multiple of point size
    if (len % @sizeOf(Point) != 0) {
        return error.InvalidBufferLength;
    }

    // pointer the BEAM memory
    const raw_buffer = data[0..len];

    // Calculate how many points we expect
    const nb_points: usize = len / (@sizeOf(f32) * 2);

    // Create a slice of f32 values (two per point)
    const float_slice = std.mem.bytesAsSlice(f32, raw_buffer);

    const colours = try beam.allocator.alloc(u8, nb_points * 4);
    defer beam.allocator.free(colours);

    var i: usize = 0;
    while (i < float_slice.len) : (i += 2) {
        if (i + 1 >= float_slice.len) break;

        const point = Point{
            .x = float_slice[i],
            .y = float_slice[i + 1],
        };

        const iterNumber = iterationNumber(point, imax);
        const rgba = createRgba(iterNumber);
        colours[i + 0] = rgba[0];
        colours[i + 1] = rgba[1];
        colours[i + 2] = rgba[2];
        colours[i + 3] = rgba[3];
        i += 4;
    }

    // For debugging
    if (nb_points > 0) {
        const first_point = Point{
            .x = float_slice[0],
            .y = float_slice[1],
        };
        std.debug.print("First point: x={d}, y={d}\n", .{
            first_point.x,
            first_point.y,
        });
    }

    return colours;
}

fn iterationNumber(p: Point, imax: usize) ?usize {
    if (p.x > 0.6 or p.x < -2.1) return null;
    if (p.y > 1.2 or p.y < -1.2) return null;
    // first cardiod
    if ((p.x + 1) * (p.x + 1) + p.y * p.y < 0.0625) return null;

    var x2: f64 = 0;
    var y2: f64 = 0;
    var w: f64 = 0;

    for (0..imax) |j| {
        if (x2 + y2 > 4) return j;
        const x: f64 = x2 - y2 + p.x;
        const y: f64 = w - x2 - y2 + p.y;
        x2 = x * x;
        y2 = y * y;
        w = (x + y) * (x + y);
    }
    return null;
}

fn createRgba(iter: ?usize, imax: usize) [3]u8 {
    // If it didn't escape, return black
    if (iter == null) return [_]u8{ 0, 0, 0 };

    if (iter.? < imax and iter.? > 0) {
        const i = iter.? % 16;
        return switch (i) {
            0 => [_]u8{ 66, 30, 15, 255 },
            1 => [_]u8{ 25, 7, 26, 255 },
            2 => [_]u8{ 9, 1, 47, 255 },
            3 => [_]u8{ 4, 4, 73, 255 },
            4 => [_]u8{ 0, 7, 100, 255 },
            5 => [_]u8{ 12, 44, 138, 255 },
            6 => [_]u8{ 24, 82, 177, 255 },
            7 => [_]u8{ 57, 125, 209, 255 },
            8 => [_]u8{ 134, 181, 229, 255 },
            9 => [_]u8{ 211, 236, 248, 255 },
            10 => [_]u8{ 241, 233, 191, 255 },
            11 => [_]u8{ 248, 201, 95, 255 },
            12 => [_]u8{ 255, 170, 0, 255 },
            13 => [_]u8{ 204, 128, 0, 255 },
            14 => [_]u8{ 153, 87, 0, 255 },
            15 => [_]u8{ 106, 52, 3, 255 },
            else => [_]u8{ 0, 0, 0, 255 },
        };
    }
    return [_]u8{ 0, 0, 0, 255 };
}
