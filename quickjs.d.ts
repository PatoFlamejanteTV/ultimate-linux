declare module "std" {
    export interface FILE {
        getline(): string | null;
        close(): void;
    }

    export function printf(fmt: string, ...args: any[]): void;
    export function open(path: string, mode: string): FILE | null;

    export const out: {
        flush(): void;
    };
}

declare module "std" {
    const _in: {
        getline(): string | null;
    };
    export { _in as in };
}

declare module "os" {
    export function getcwd(): [string, number];
    export function readdir(path: string): [string[], number];
    export function chdir(path: string): number;
    export function mkdir(path: string, mode: number): number;
}
