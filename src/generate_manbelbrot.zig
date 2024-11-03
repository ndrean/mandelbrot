// const std = @import("std");
// const e = @cImport({
//     @cInclude("erl_nif.h");
// });

// export fn generate_mandlebrot(env: ?*e.ErlNifEnv, imax: c_int, resolution_x: c_int, resolution_y: c_int, allocator: std.mem.allocator) e.ERL_NIF_TERM {
//   const pixels = try createBands(ctx, allocator);
//   return pixels;
// }

// export fn processRows(pixels: []u8, start_row: usize, end_row: usize, resolution_x: usize, resolution_y: usize) void {
//     for (start_row..end_row) |current_row| {
//         processRow(pixels, current_row, resolution_x, resolution_y);
//     }
// }

// export fn processRow(pixels: []u8, row_id: usize, resolution_X: usize, resolution_y: usize) void {
//     // Calculate the symmetric row
//     const sym_row_id = resolution_y - 1 - row_id;

//     if (row_id <= sym_row_id) {
//         // loop over columns
//         for (0..resolution_y) |col_id| {
//             const c = pixelToComplex(.{ @as(u32, @intCast(col_id)), @as(u32, @intCast(row_id)) }, ctx);
//             const iter = getIter(c);
//             const colour = createRgb(iter);

//             const p_idx = (row_id * ctx.resolution[0] + col_id) * 3;
//             pixels[p_idx + 0] = colour[0];
//             pixels[p_idx + 1] = colour[1];
//             pixels[p_idx + 2] = colour[2];

//             // Process the symmetric row (if it's different from current row)
//             if (row_id != sym_row_id) {
//                 const sym_p_idx = (sym_row_id * ctx.resolution[0] + col_id) * 3;
//                 pixels[sym_p_idx + 0] = colour[0];
//                 pixels[sym_p_idx + 1] = colour[1];
//                 pixels[sym_p_idx + 2] = colour[2];
//             }
//         }
//     }
// }

// export fn pixelToComplex(pix: [2]u32, resolution_X: usize, resolution_y: usize) Cx {
//     const w = ctx.bottomRight.re - ctx.topLeft.re;
//     const h = ctx.topLeft.im - ctx.bottomRight.im;
//     const re = @as(f64, @floatFromInt(pix[0])) / @as(f64, @floatFromInt(ctx.resolution[0])) * w;
//     const im = @as(f64, @floatFromInt(pix[1])) / @as(f64, @floatFromInt(ctx.resolution[1])) * h;
//     return Cx{ .re = (ctx.topLeft.re + re) * w, .im = (ctx.topLeft.im - im) * h };
// }
