# Advent of Code 2023

done by: milan@aleksic.dev

Using: zig v0.11.0

## Improvements

- [x] stable naming of functions and tests
- [x] multi-line test source instead of manual `append` calls
- [ ] ~switch places for equals comparison in tests, figure out the comptime error cause~ (https://github.com/ziglang/zig/issues/4437)
- [x] named structs as function results in day2
- [x] use test allocator in prod code as arg to verify no leaks occur
- [x] try different allocators (arena maybe?)