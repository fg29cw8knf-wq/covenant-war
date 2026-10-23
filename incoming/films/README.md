# Gary's 4K opening film, in parts (23 October 2026)

`opening_4k.mp4` is Gary's finished opening movie: his three 4K 60 fps parts
joined losslessly with `ffmpeg -f concat -c copy` (3:14.6, H.264 3840x2160,
AAC, 417 MB). GitHub takes no file over 100 MB, and this session couldn't
create releases, so it's here in 90 MB pieces for the next session to put on
the `films` release (a workflow step with `gh release create films ...` can;
Actions may create releases) and then delete from the branch:

    cat incoming/films/opening_4k.mp4.part? > opening_4k.mp4
    shasum -a 256 -c incoming/films/opening_4k.mp4.sha256   # 431f756b...b5a2

Keep it off `main`: the apps fetch it from the release (tools/fetch_native.sh,
to be written), and `addons/native_video/films/` is where the export plugin
looks for it.
