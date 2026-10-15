#!/usr/bin/env python3
"""Lists the files in a Godot 4 .pck, largest first, with a total per folder.

    python3 tools/pck_list.py build/web/index.pck [how many files to show]
"""
import collections
import struct
import sys


def entries(path):
    with open(path, "rb") as f:
        assert f.read(4) == b"GDPC", "not a Godot pack"
        version, _maj, _min, _pat, flags, base = struct.unpack("<IIIIIQ", f.read(28))
        if version >= 3:
            dir_offset = struct.unpack("<Q", f.read(8))[0]
            f.seek(dir_offset)
        else:
            f.read(16 * 4)
        assert not flags & 1, "encrypted directory"
        for _ in range(struct.unpack("<I", f.read(4))[0]):
            n = struct.unpack("<I", f.read(4))[0]
            name = f.read(n).rstrip(b"\0").decode()
            _ofs, size = struct.unpack("<QQ", f.read(16))
            f.read(16 + 4)  # md5, flags
            yield name, size


if __name__ == "__main__":
    files = sorted(entries(sys.argv[1]), key=lambda e: -e[1])
    show = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    for name, size in files[:show]:
        print("%8.2f MB  %s" % (size / 1048576, name))
    groups = collections.Counter()
    for name, size in files:
        groups["/".join(name.split("/")[:5])] += size
    print("-- by folder --")
    for g, size in groups.most_common(25):
        print("%8.2f MB  %s" % (size / 1048576, g))
    print("%d files, %.1f MB" % (len(files), sum(s for _, s in files) / 1048576))
