"""Generate a simple PNG icon for the Android app launcher."""
import struct, zlib, os

def create_png(width, height, r, g, b):
    """Create a simple solid-color PNG image."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        return struct.pack('>I', len(data)) + c + crc

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
    
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter byte
        for x in range(width):
            # Simple circle in center
            cx, cy = width/2, height/2
            radius = min(width, height) / 2 * 0.8
            dx = x - cx
            dy = y - cy
            if dx*dx + dy*dy <= radius*radius:
                raw_data += bytes([r, g, b])
            else:
                raw_data += bytes([0, 0, 0, 0])  # transparent - but RGB mode doesn't support alpha
    
    # Actually for RGB mode, let's just fill with the color
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'
        for x in range(width):
            cx, cy = width/2, height/2
            radius = min(width, height) / 2 * 0.75
            dx = x - cx
            dy = y - cy
            if dx*dx + dy*dy <= radius*radius:
                raw_data += bytes([r, g, b])
            else:
                raw_data += bytes([r//2, g//2, b//2])
    
    idat = chunk(b'IDAT', zlib.compress(raw_data))
    iend = chunk(b'IEND', b'')
    
    return header + ihdr + idat + iend

base_path = r"C:\Users\Administrator\WorkBuddy\Claw\kline_app\android\app\src\main\res"

# Generate icons for each density
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, size in sizes.items():
    dir_path = os.path.join(base_path, folder)
    os.makedirs(dir_path, exist_ok=True)
    png_data = create_png(size, size, 0x00, 0xD4, 0xAA)  # Brand color
    with open(os.path.join(dir_path, "ic_launcher.png"), "wb") as f:
        f.write(png_data)
    print(f"Created {folder}/ic_launcher.png ({size}x{size})")

print("All icons created!")
