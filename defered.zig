const print = @import("std").debug.print;

fn addSingleDigits(a: u32, b: u32) !u32 {
    defer print("this is deferred!");

    if (a > 9) return error.DigitTooLarge;
    if (b > 9) return error.DigitTooLarge;

    return a + b;
}

pub fn main() void {
    addSingleDigits(10, 20);
}
