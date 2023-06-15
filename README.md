# TinyLZW
This project is meant to become a collection of tiny variable LZW implementations in x86 (16 bit) assembly for sizecoding purposes. It is about keeping the code footprint small to use it as a decompressor for tiny executables (mostly COM files) for demoscene productions in the < 1 kB size range. Versions for Z80 and other CPUs should also be possible.

This is work in progress. Right now only a stack based variant is included. An iterative and a recursive variant will follow soon.

# Implementation Details
For storing the dictionary I had the idea of using a <link, char> table structure, which ofc already had been described somewhere in the past as I found out. This means that for every new dictionary entry only the current code and the successing character have to be stored. To reconstruct the full string, the codes pointing to other dictionary entries (100h and upward) simply have to be followed recursively.

The main loop without bitstream decoder (which can vary based on the format: n bits, n-8 bits + byte, phased in binary etc.) is 29 bytes right now (working this way on P4 and later platforms due to the zero flag being set by IMUL there). There are defines to select safe/unsafe and IMUL flag behaviour variants.

The code is not fully tested. I'll add some basic tests to it soon. Right now testing is done in stepwise debugging.

# License
[MIT License](https://choosealicense.com/licenses/mit/)
