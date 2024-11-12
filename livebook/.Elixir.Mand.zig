// this code is autogenerated, do not check it into to your code repository

// ref /Users/nevendrean/code/zig/mandelbrot/livebook/mandelbrot.livemd#cell:kdihprz3mmbb5ji5:7
  const beam = @import("beam");
  const std = @import("std");
  const Cx = std.math.Complex(f64);
  
  const print = std.debug.print;
  
  const Context = struct { res_x: usize, res_y: usize, imax: usize, w: f64, h: f64, topLeft: Cx, bottomRight: Cx };
  
  /// nif: generate_misiurewicz/7 Threaded
  pub fn generate_misiurewicz(res_x: usize, res_y: usize, imax: usize, topLeft_x: f64, topLeft_y: f64, bottomRight_x: f64, bottomRight_y: f64) !beam.term {
      const pixels = try beam.allocator.alloc(u8, res_x * res_y * 3);
      defer beam.allocator.free(pixels);
  
      const tl = Cx{ .re = topLeft_x, .im = topLeft_y };
      const br = Cx{ .re = bottomRight_x, .im = bottomRight_y };
      const w = br.re - tl.re;
      const h = br.im - tl.im;
      // threaded version
      const ctx = Context{ .res_x = res_x, .res_y = res_y, .imax = imax, .topLeft = tl, .bottomRight = br, .w = w, .h = h };
      const res = try createBands(pixels, ctx);
      return beam.make(res, .{ .as = .binary });
  }
  
  // <--- threaded version
  fn createBands(pixels: []u8, ctx: Context) ![]u8 {
      const cpus = try std.Thread.getCpuCount();
      var threads = try beam.allocator.alloc(std.Thread, cpus);
      defer beam.allocator.free(threads);
  
      const rows_to_process = ctx.res_y;
      // one band is one count of cpus
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
  
  fn processRows(ctx: Context, pixels: []u8, start_row: usize, end_row: usize) void {
      for (start_row..end_row) |current_row| {
          processRow(ctx, pixels, current_row);
      }
  }
  
  fn processRow(ctx: Context, pixels: []u8, row_id: usize) void {
      // loop over columns
      for (0..ctx.res_x) |col_id| {
          const c = mapPixel(.{ @as(usize, @intCast(row_id)), @as(usize, @intCast(col_id)) }, ctx);
          const iter = iterationNumber(c, ctx.imax);
          const colour = createRgb2(iter, ctx.imax);
  
          const p_idx = (row_id * ctx.res_x + col_id) * 3;
          pixels[p_idx + 0] = colour[0];
          pixels[p_idx + 1] = colour[1];
          pixels[p_idx + 2] = colour[2];
      }
  }
  
  fn mapPixel(pixel: [2]usize, ctx: Context) Cx {
      const px_width = ctx.res_x - 1;
      const px_height = ctx.res_y - 1;
      const scale_x = ctx.w / @as(f64, @floatFromInt(px_width));
      const scale_y = ctx.h / @as(f64, @floatFromInt(px_height));
  
      const re = ctx.topLeft.re + scale_x * @as(f64, @floatFromInt(pixel[1]));
      const im = ctx.topLeft.im + scale_y * @as(f64, @floatFromInt(pixel[0]));
      return Cx{ .re = re, .im = im };
  }
  
  fn iterationNumber(c: Cx, imax: usize) ?usize {
      if (c.re > 0.6 or c.re < -2.1) return null;
      if (c.im > 1.2 or c.im < -1.2) return null;
      // first cardiod
      if ((c.re + 1) * (c.re + 1) + c.im * c.im < 0.0625) return null;
  
      var x2: f64 = 0;
      var y2: f64 = 0;
      var w: f64 = 0;
  
      for (0..imax) |j| {
          if (x2 + y2 > 4) return j;
          const x: f64 = x2 - y2 + c.re;
          const y: f64 = w - x2 - y2 + c.im;
          x2 = x * x;
          y2 = y * y;
          w = (x + y) * (x + y);
      }
  
      // var z = Cx{ .re = 0.0, .im = 0.0 };
      // for (0..imax) |j| {
      //     if (sqnorm(z) > 4) return j;
      //     z = Cx.mul(z, z).add(c);
      // }
      return null;
  }
  
  fn sqnorm(z: Cx) f64 {
      return z.re * z.re + z.im * z.im;
  }
  
  
  fn createRgb2(iter: ?usize, imax: usize) [3]u8 {
      // If it didn't escape, return black
      if (iter == null) return [_]u8{ 0, 0, 0 };
  
      if (iter.? < imax and iter.? > 0) {
          const i = iter.? % 16;
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
