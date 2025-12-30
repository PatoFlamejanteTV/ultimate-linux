const std = @import("std");

const c = @cImport({
    @cInclude("quickjs-libc.h");
    @cInclude("sys/mount.h");
    @cInclude("errno.h");
    @cInclude("string.h");
});

fn js_get_err(ctx: ?*c.JSContext) c.JSValue {
    // Access errno via __errno_location pointer
    // If c.errno fails due to comptime eval, we can try calling __errno_location explicitly at runtime.
    // In @cImport, `errno` might be defined as `__errno_location().*` which Zig doesn't like at comptime if it thinks it is being used there.
    // But here we are in a function.

    // Using std.c.getErrno or similar might be better, but let's try direct C call if we can find the symbol.
    // Or just use the pointer.
    const err = c.__errno_location().*;
    return c.JS_NewInt32(ctx, -err);
}

// Removed export to match static behavior in C
fn js_mount(ctx: ?*c.JSContext, this_val: c.JSValueConst, argc: c_int, argv: [*c]c.JSValueConst) callconv(.C) c.JSValue {
    _ = this_val;
    _ = argc;
    const source = c.JS_ToCString(ctx, argv[0]);
    const target = c.JS_ToCString(ctx, argv[1]);
    const type_ = c.JS_ToCString(ctx, argv[2]);

    const res = c.mount(source, target, type_, 0, null);

    c.JS_FreeCString(ctx, source);
    c.JS_FreeCString(ctx, target);
    c.JS_FreeCString(ctx, type_);

    if (res < 0) return js_get_err(ctx);
    return c.JS_NewInt32(ctx, 0);
}

// Helper to create JSCFunctionListEntry for JS_CFUNC_DEF
fn js_cfunc_def(name: [*c]const u8, length: u8, func1: c.JSCFunction) c.JSCFunctionListEntry {
    var entry: c.JSCFunctionListEntry = undefined;
    entry.name = name;
    entry.prop_flags = c.JS_PROP_WRITABLE | c.JS_PROP_CONFIGURABLE;
    entry.def_type = c.JS_DEF_CFUNC;
    entry.magic = 0;
    // Initialize the union
    entry.u.func.length = length;
    entry.u.func.cproto = c.JS_CFUNC_generic;
    entry.u.func.cfunc.generic = func1;
    return entry;
}

const js_sys_ops_funcs = [_]c.JSCFunctionListEntry{
    js_cfunc_def("mount", 3, js_mount),
};

fn js_sys_ops_init(ctx: ?*c.JSContext, m: ?*c.JSModuleDef) callconv(.C) c_int {
    return c.JS_SetModuleExportList(ctx, m, &js_sys_ops_funcs[0], js_sys_ops_funcs.len);
}

export fn js_init_module_js_init_module_sys_ops(ctx: ?*c.JSContext, module_name: [*c]const u8) callconv(.C) ?*c.JSModuleDef {
    const m = c.JS_NewCModule(ctx, module_name, js_sys_ops_init);
    if (m == null) return null;
    _ = c.JS_AddModuleExportList(ctx, m, &js_sys_ops_funcs[0], js_sys_ops_funcs.len);
    return m;
}
