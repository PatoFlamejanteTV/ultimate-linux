/// <reference path="quickjs.d.ts" />
/// <reference path="sys_ops.d.ts" />

import * as std from "std";
import * as os from "os";
import { mount } from "sys_ops";

function printHelp(): void {
    std.printf("Commands: ls, cd, cat, mkdir, mount, exit\n");
}

// Native Cat: Works without /bin/cat
function cat(path: string): void {
    const f = std.open(path, "r");
    if (!f) {
        std.printf("cat: %s: No such file\n", path);
        return;
    }
    let line: string | null;
    while ((line = f.getline()) !== null) {
        std.printf("%s\n", line);
    }
    f.close();
}

std.printf("--- ULTIMATE LINUX SHELL ---\n");
printHelp();

while (true) {
    const cwd_res = os.getcwd();
    const cwd = cwd_res[0] || "/";
    std.printf("[%s] # ", cwd);
    std.out.flush();

    const line = std.in.getline();
    if (line === null) break;

    const input = line.trim();
    if (!input) continue;

    const args = input.split(/\s+/);
    const cmd = args[0];

    try {
        if (cmd === "ls") {
            const [files, err] = os.readdir(args[1] || ".");
            if (err !== 0) std.printf("ls error: %d\n", err);
            else {
                files.forEach(f => std.printf("%s  ", f));
                std.printf("\n");
            }
        } 
        else if (cmd === "cd") {
            os.chdir(args[1] || "/");
        } 
        else if (cmd === "cat") {
            cat(args[1]);
        }
        else if (cmd === "mount") {
            const res = mount(args[1], args[2], args[3] || "ext4");
            std.printf("Mount %s -> %s: %s\n", args[1], args[2], res === 0 ? "Success" : "Error " + res);
        }
        else if (cmd === "mkdir") {
            const path = args[1];
            if (!path) {
                std.printf("usage: mkdir <path>\n");
            } else {
                // 0o755 is the standard octal for rwxr-xr-x
                const res = os.mkdir(path, 0o755); 
                if (res !== 0) {
                    std.printf("mkdir: cannot create '%s' (error %d)\n", path, res);
                }
            }
        }
        else if (cmd === "help") {
            printHelp();
        }
        else if (cmd === "exit") {
            break;
        }
        else {
            std.printf("No idea what to do lol\n");
        }
    } catch (e: any) {
        std.printf("Shell Error: %s\n", e.toString());
    }
}
