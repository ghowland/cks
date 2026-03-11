const std = @import("std");

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn sub(a: i32, b: i32) i32 {
    return a - b;
}

pub fn mul(a: i32, b: i32) i32 {
    return a * b;
}

pub fn max(a: i32, b: i32) i32 {
    if (a > b) return a;
    return b;
}

pub fn min(a: i32, b: i32) i32 {
    if (a < b) return a;
    return b;
}

pub fn abs(x: i32) i32 {
    if (x < 0) return -x;
    return x;
}

pub fn clamp(val: i32, lo: i32, hi: i32) i32 {
    if (val < lo) return lo;
    if (val > hi) return hi;
    return val;
}

const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return .{ .x = x, .y = y };
    }

    pub fn distance_sq(self: Point, other: Point) i32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return dx * dx + dy * dy;
    }
};

const ArrayList = struct {
    items: []i32,
    len: usize,
    capacity: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ArrayList {
        return .{
            .items = &[_]i32{},
            .len = 0,
            .capacity = 0,
            .allocator = allocator,
        };
    }

    pub fn append(self: *ArrayList, item: i32) !void {
        if (self.len >= self.capacity) {
            const new_cap = if (self.capacity == 0) 8 else self.capacity * 2;
            const new_items = try self.allocator.alloc(i32, new_cap);
            if (self.len > 0) {
                @memcpy(new_items[0..self.len], self.items[0..self.len]);
                self.allocator.free(self.items);
            }
            self.items = new_items;
            self.capacity = new_cap;
        }
        self.items[self.len] = item;
        self.len += 1;
    }

    pub fn get(self: *const ArrayList, index: usize) i32 {
        return self.items[index];
    }

    pub fn deinit(self: *ArrayList) void {
        if (self.capacity > 0) {
            self.allocator.free(self.items);
        }
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const a = add(10, 20);
    const b = sub(50, 30);
    const c = mul(a, b);

    try stdout.print("a={d} b={d} c={d}\n", .{ a, b, c });

    const p1 = Point.init(0, 0);
    const p2 = Point.init(3, 4);
    const dist = p1.distance_sq(p2);
    try stdout.print("distance_sq={d}\n", .{dist});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = ArrayList.init(allocator);
    defer list.deinit();

    var i: i32 = 0;
    while (i < 10) : (i += 1) {
        try list.append(i * i);
    }

    try stdout.print("squares: ", .{});
    for (0..list.len) |idx| {
        try stdout.print("{d} ", .{list.get(idx)});
    }
    try stdout.print("\n", .{});
}
