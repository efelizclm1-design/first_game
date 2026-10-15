"""Package a clean, portable Godot source project. Does not include user saves."""
from pathlib import Path
import zipfile, hashlib
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent / 'PixelPanic-delivery'
OUT.mkdir(exist_ok=True)
archive = OUT / 'PixelPanic-Godot.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for path in sorted(ROOT.rglob('*')):
        relative = path.relative_to(ROOT)
        if any(part in {'.git', '.godot', 'exports', '__pycache__'} for part in relative.parts):
            continue
        if path.is_file() and path.suffix not in {'.tmp', '.log'}:
            z.write(path, str(Path('PixelPanic') / relative))
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert 'PixelPanic/project.godot' in z.namelist()
    assert 'PixelPanic/scenes/main.tscn' in z.namelist()
    assert not any('/.git/' in n or '/.godot/' in n for n in z.namelist())
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
(OUT / 'PixelPanic-Godot.sha256').write_text(checksum + '  ' + archive.name + '\n')
print(f'{archive}: {archive.stat().st_size:,} bytes')
print('SHA-256:', checksum)
