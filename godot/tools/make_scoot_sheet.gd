extends SceneTree
# make_scoot_sheet.gd — packs the two-cell SCOOT sheet (CHANGE-BRIEF.md, "Sheet and cycle").
#
# What it does:
#   Loads CHAR-SCOOT-A.png (cell 0, left) and CHAR-SCOOT-B.png (cell 1, right)
#   straight from the PNG files (Image.load_from_file, not the imported
#   textures), copies them side by side into a new 2048 x 1024 RGBA8 image with
#   no mipmaps, no scaling, no padding, and saves it as CHAR-SCOOT-SHEET.png.
#   If the sheet already exists it is never overwritten: identical -> "unchanged",
#   different -> FAILED (exit 1).
#
# Run (from the repository root; Kiran reviews and runs it):
#   godot --headless --path godot --script res://tools/make_scoot_sheet.gd
#   Exit 0 = SCOOT SHEET: OK, exit 1 = SCOOT SHEET: FAILED (<reason>).
#
# What it checks:
#   - each source loads as exactly 1024 x 1024 FORMAT_RGBA8 (no conversion);
#   - the packed image matches both sources byte for byte before any write;
#   - after saving (or finding it unchanged), the sheet reloaded from disk is
#     2048 x 1024 FORMAT_RGBA8 and each cell's raw RGBA bytes equal its source's;
#   - prints mismatched-pixel counts per cell, image sizes and formats, and the
#     SHA-256 of both sources and of the sheet file.
#
# Writes only res://assets/art/CHAR-SCOOT-SHEET.png. Never writes the source
# PNGs or any .import file. The source frames are Kiran Gowda's A2 artwork; their
# provenance is in CHANGE-BRIEF.md ("Sheet and cycle") and ASSET-LOG.md.
#
# Written by Claude Code at Kiran's request (A7); not yet run.

const SRC_A := "res://assets/art/CHAR-SCOOT-A.png"
const SRC_B := "res://assets/art/CHAR-SCOOT-B.png"
const OUT := "res://assets/art/CHAR-SCOOT-SHEET.png"

# SHA-256 values recorded in CHANGE-BRIEF.md ("Sheet and cycle"). Printed for
# comparison only; a mismatch is reported but does not change the exit code.
const BRIEF_SHA_A := "6aa35cf27aa3ed6202f2d0254f1defe456d0db4a387981cf0104be03af6b916a"
const BRIEF_SHA_B := "f95dacdb13614d9ed7d4a5798e3bf6df8902d5dcd5186f368631bcce0a4bb271"

const CELL := 1024
const CELLS := 2
const SHEET_W := CELL * CELLS
const SHEET_H := CELL
const BPP := 4                          # bytes per pixel in FORMAT_RGBA8
const CELL_ROW := CELL * BPP            # bytes in one row of one cell
const SHEET_ROW := SHEET_W * BPP        # bytes in one row of the sheet


func _initialize() -> void:
    var code := _run()
    quit(code)


func _run() -> int:
    print("SCOOT SHEET: packing ", SRC_A, " + ", SRC_B, " -> ", OUT)

    # --- Sources -----------------------------------------------------------
    var src_paths := [SRC_A, SRC_B]
    var brief_shas := [BRIEF_SHA_A, BRIEF_SHA_B]
    var sources: Array[Image] = []
    for i: int in range(CELLS):
        var res_path: String = src_paths[i]
        var global_path := ProjectSettings.globalize_path(res_path)
        if not FileAccess.file_exists(global_path):
            return _fail("source missing: " + res_path)
        var sha := FileAccess.get_sha256(global_path)
        print("SOURCE ", i, ": ", res_path, " sha256=", sha,
                " brief_sha256_match=", sha == brief_shas[i])
        var img := Image.load_from_file(global_path)
        if img == null or img.is_empty():
            return _fail("source did not load: " + res_path)
        print("SOURCE ", i, ": size=", img.get_width(), "x", img.get_height(),
                " format=", _fmt(img.get_format()), " mipmaps=", img.has_mipmaps())
        if img.get_width() != CELL or img.get_height() != CELL \
                or img.get_format() != Image.FORMAT_RGBA8 or img.has_mipmaps():
            return _fail("source %s loaded as %dx%d %s mipmaps=%s, expected 1024x1024 RGBA8 without mipmaps" % [
                    res_path, img.get_width(), img.get_height(),
                    _fmt(img.get_format()), str(img.has_mipmaps())])
        if img.get_data().size() != CELL * CELL * BPP:
            return _fail("source %s has %d data bytes, expected %d" % [
                    res_path, img.get_data().size(), CELL * CELL * BPP])
        sources.append(img)

    # --- Pack --------------------------------------------------------------
    var sheet := Image.create_empty(SHEET_W, SHEET_H, false, Image.FORMAT_RGBA8)
    if sheet == null or sheet.is_empty():
        return _fail("could not create the 2048x1024 sheet image")
    for i: int in range(CELLS):
        # blit_rect overwrites the destination pixels (no blending, no filtering).
        sheet.blit_rect(sources[i], Rect2i(0, 0, CELL, CELL), Vector2i(i * CELL, 0))
    print("PACKED: size=", sheet.get_width(), "x", sheet.get_height(),
            " format=", _fmt(sheet.get_format()), " mipmaps=", sheet.has_mipmaps())

    # Check the in-memory pack before anything touches the disk.
    var packed_data := sheet.get_data()
    for i: int in range(CELLS):
        var bad := _count_mismatches(packed_data, sources[i].get_data(), i)
        print("PACKED cell ", i, ": mismatched pixels=", bad)
        if bad != 0:
            return _fail("packed cell %d differs from its source in %d pixels" % [i, bad])

    # --- Output ------------------------------------------------------------
    var out_global := ProjectSettings.globalize_path(OUT)
    if FileAccess.file_exists(out_global):
        var existing := Image.load_from_file(out_global)
        var same := existing != null and not existing.is_empty() \
                and existing.get_width() == SHEET_W and existing.get_height() == SHEET_H \
                and existing.get_format() == Image.FORMAT_RGBA8 \
                and existing.get_data() == packed_data
        if not same:
            print("OUTPUT: ", OUT, " exists and differs from the fresh pack; not written. sha256=",
                    FileAccess.get_sha256(out_global))
            return _fail("existing sheet differs from the fresh pack; not overwritten")
        print("OUTPUT: ", OUT, " unchanged (pixel-identical to the fresh pack); not written")
    else:
        var err := sheet.save_png(out_global)
        if err != OK:
            return _fail("save_png returned error %d (%s)" % [err, error_string(err)])
        print("OUTPUT: ", OUT, " written")

    # --- Verify from disk --------------------------------------------------
    var disk := Image.load_from_file(out_global)
    if disk == null or disk.is_empty():
        return _fail("sheet did not reload from disk")
    print("OUTPUT: size=", disk.get_width(), "x", disk.get_height(),
            " format=", _fmt(disk.get_format()), " mipmaps=", disk.has_mipmaps(),
            " sha256=", FileAccess.get_sha256(out_global))
    if disk.get_width() != SHEET_W or disk.get_height() != SHEET_H \
            or disk.get_format() != Image.FORMAT_RGBA8:
        return _fail("sheet reloaded as %dx%d %s, expected 2048x1024 RGBA8" % [
                disk.get_width(), disk.get_height(), _fmt(disk.get_format())])
    var disk_data := disk.get_data()
    if disk_data.size() != SHEET_W * SHEET_H * BPP:
        return _fail("sheet has %d data bytes, expected %d" % [
                disk_data.size(), SHEET_W * SHEET_H * BPP])
    var total_bad := 0
    for i: int in range(CELLS):
        var bad := _count_mismatches(disk_data, sources[i].get_data(), i)
        print("VERIFY cell ", i, " (", src_paths[i], "): mismatched pixels=", bad)
        total_bad += bad
    if total_bad != 0:
        return _fail("sheet on disk differs from its sources in %d pixels" % total_bad)

    print("SCOOT SHEET: OK")
    return 0


# Counts pixels in sheet cell `cell` whose 4 RGBA bytes differ from the source.
# Compares one cell row at a time; only rows that differ are scanned per pixel.
func _count_mismatches(sheet_data: PackedByteArray, src_data: PackedByteArray, cell: int) -> int:
    var bad := 0
    for y: int in range(CELL):
        var s0 := y * SHEET_ROW + cell * CELL_ROW
        var r0 := y * CELL_ROW
        var sheet_row := sheet_data.slice(s0, s0 + CELL_ROW)
        var src_row := src_data.slice(r0, r0 + CELL_ROW)
        if sheet_row == src_row:
            continue
        for x: int in range(CELL):
            var b := x * BPP
            if sheet_row[b] != src_row[b] or sheet_row[b + 1] != src_row[b + 1] \
                    or sheet_row[b + 2] != src_row[b + 2] or sheet_row[b + 3] != src_row[b + 3]:
                bad += 1
    return bad


func _fmt(f: int) -> String:
    match f:
        Image.FORMAT_L8: return "L8"
        Image.FORMAT_LA8: return "LA8"
        Image.FORMAT_RGB8: return "RGB8"
        Image.FORMAT_RGBA8: return "RGBA8"
        Image.FORMAT_RGBA4444: return "RGBA4444"
        Image.FORMAT_RGBH: return "RGBH"
        Image.FORMAT_RGBAH: return "RGBAH"
    return "format#%d" % f


func _fail(reason: String) -> int:
    print("SCOOT SHEET: FAILED (", reason, ")")
    return 1
