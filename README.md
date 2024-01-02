# Advent of Code 2023

done by: milan@aleksic.dev

Using: zig v0.11.0

> Note: I am a Zig newbie & using AoC to learn as-I-go

```bash
➜ ./run.sh

...

# no dependencies beyond system
➜ otool -L zig-out/bin/adventofcode2023
zig-out/bin/adventofcode2023:
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1336.0.0)

➜ mls zig-out/bin/adventofcode2023
.rwxr-xr-x milan staff 233 KB Wed Dec  6 12:55:08 2023  zig-out/bin/adventofcode2023
```

## Improvements

- [x] stable naming of functions and tests
- [x] multi-line test source instead of manual `append` calls
- [ ] ~switch places for equals comparison in tests, figure out the comptime error cause~ (https://github.com/ziglang/zig/issues/4437)
- [x] named structs as function results in day2
- [x] use test allocator in prod code as arg to verify no leaks occur
- [x] try different allocators (arena maybe?)

## Days I reached out for help

- day 8, part 2 (decision to use LCM)
- day 18, part 2 (Pick's theorem and Shoelace formula)
