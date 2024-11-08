// this code is autogenerated, do not check it into to your code repository

// ref mandelbrot/livebook/mandelbrot.livemd#cell:wrryse7e5c6cnnxb:6
  const beam = @import("beam");
  const std = @import("std");
  const Cx = std.math.Complex(f64);

  const topLeft = Cx{ .re = -2.1, .im = 1.2 };
  const bottomRight = Cx{ .re = 0.6, .im = -1.2 };
  const w = bottomRight.re - topLeft.re;
  const h = bottomRight.im - topLeft.im;
  
  const Context = struct {res_x: usize, res_y: usize, imax: usize};
  
  /// nif: generate_mandelbrot/3 Threaded
  pub fn generate_mandelbrot(res_x: usize, res_y: usize, max_iter: usize) !beam.term {
      const pixels = try beam.allocator.alloc(u8, res_x * res_y * 3);
      defer beam.allocator.free(pixels);
  
      const resolution = Context{ .res_x = res_x, .res_y = res_y, .imax = max_iter };

      const res = try createBands(pixels, resolution);
      return beam.make(res, .{ .as = .binary });
  }

  // <--- threaded version
  fn createBands(pixels: []u8, ctx: Context) ![]u8 {
      const cpus = try std.Thread.getCpuCount();
      var threads = try beam.allocator.alloc(std.Thread, cpus);
      defer beam.allocator.free(threads);
  
      // half of the total rows
      const rows_to_process = ctx.res_y / 2 + ctx.res_y % 2;
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

  fn processRows(ctx: Context, pixels: []u8, start_row: usize, end_row: usize) void {
      for (start_row..end_row) |current_row| {
          processRow(ctx, pixels, current_row);
      }
  }

  fn processRow(ctx: Context, pixels: []u8, row_id: usize) void {
      // Calculate the symmetric row
      const sym_row_id = ctx.res_y - 1 - row_id;
  
      if (row_id <= sym_row_id) {
          // loop over columns
          for (0..ctx.res_x) |col_id| {
              const c = mapPixel(.{ @as(usize, @intCast(row_id)), @as(usize, @intCast(col_id)) }, ctx);
              const iter = iterationNumber(c, ctx.imax);
              const colour = createRgb(iter, ctx.imax);
  
              const p_idx = (row_id * ctx.res_x + col_id) * 3;
              pixels[p_idx + 0] = colour[0];
              pixels[p_idx + 1] = colour[1];
              pixels[p_idx + 2] = colour[2];
  
              // Process the symmetric row (if it's different from current row)
              if (row_id != sym_row_id) {
                  const sym_p_idx = (sym_row_id * ctx.res_x + col_id) * 3;
                  pixels[sym_p_idx + 0] = colour[0];
                  pixels[sym_p_idx + 1] = colour[1];
                  pixels[sym_p_idx + 2] = colour[2];
              }
          }
      }
  }

  fn mapPixel(pixel: [2]usize, ctx: Context) Cx {
      const px_width = ctx.res_x - 1;
      const px_height = ctx.res_y - 1;
      const scale_x = w / @as(f64, @floatFromInt(px_width));
      const scale_y = h / @as(f64, @floatFromInt(px_height));
  
      const re = topLeft.re + scale_x * @as(f64, @floatFromInt(pixel[1]));
      const im = topLeft.im + scale_y * @as(f64, @floatFromInt(pixel[0]));
      return Cx{ .re = re, .im = im };
  }

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

  fn sqnorm(z: Cx) f64 {
      return z.re * z.re + z.im * z.im;
  }
  
  fn createRgb(iter: ?usize, imax: usize) [3]u8 {
      // If it didn't escape, return black
      if (iter == null) return [_]u8{ 0, 0, 0 };
  
      // Normalize time to [0,1[ now that we know it isn't "null"
      const normalized = @as(f64, @floatFromInt(iter.?)) / @as(f64, @floatFromInt(imax));
  
      if (normalized < 0.5) {
          const scaled = normalized * 2;
          return [_]u8{ @as(u8, @intFromFloat(255 * (1 - scaled))), @as(u8, @intFromFloat(255.0 * (1 - scaled / 2))), @as(u8, @intFromFloat(127 + 128 * scaled)) };
      } else {
          const scaled = (normalized - 0.5) * 2.0;
          return [_]u8{ 0, @as(u8, @intFromFloat(127 * (1 - scaled / 2))), @as(u8, @intFromFloat(255 * (1 - scaled))) };
      }
  }

