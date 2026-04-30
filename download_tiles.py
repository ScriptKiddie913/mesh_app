import os
import urllib.request
import math

def download_tiles(max_zoom=2):
    base_url = "https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png"
    base_dir = "assets/tiles"
    
    total_downloaded = 0
    for z in range(max_zoom + 1):
        num_tiles = int(math.pow(2, z))
        for x in range(num_tiles):
            for y in range(num_tiles):
                tile_url = base_url.format(z=z, x=x, y=y)
                tile_dir = os.path.join(base_dir, str(z), str(x))
                os.makedirs(tile_dir, exist_ok=True)
                
                tile_path = os.path.join(tile_dir, f"{y}.png")
                
                try:
                    req = urllib.request.Request(tile_url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req) as response, open(tile_path, 'wb') as out_file:
                        out_file.write(response.read())
                    print(f"Downloaded {tile_path}")
                    total_downloaded += 1
                except Exception as e:
                    print(f"Failed to download {tile_url}: {e}")
                    
    print(f"Total tiles downloaded: {total_downloaded}")

if __name__ == "__main__":
    download_tiles(2)
