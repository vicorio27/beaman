"""Pasa todas las hojas de assets/tilesets/source/ a la paleta del juego:
Resurrect 64 (Lospec) + tonos urbanos propios (grises cálidos, tierras, verdes gastados).
Cada píxel va al color de la paleta más cercano en OKLab (distancia perceptual).
Antes se aplica un leve corrimiento cálido y de contraste para que el resultado no quede lavado.
Uso (desde la carpeta del proyecto): python tools/art/apply_palette.py"""
import colorsys
from pathlib import Path
import numpy as np
from PIL import Image

PALETTE = """2e222f 3e3546 625565 966c6c ab947a 694f62 7f708a 9babb2 c7dcd0 ffffff 6e2727 b33831
ea4f36 f57d4a ae2334 e83b3b fb6b1d f79617 f9c22b 7a3045 9e4539 cd683d e6904e fbb954 4c3e24 676633
a2a947 d5e04b fbff86 165a4c 239063 1ebc73 91db69 cddf6c 313638 374e4a 547e64 92a984 b2ba90 0b5e65
0b8a8f 0eaf9b 30e1b9 8ff8e2 323353 484a77 4d65b4 4d9be6 8fd3ff 45293f 6b3e75 905ea9 a884f3 eaaded
753c54 a24b6f cf657f ed8099 831c5d c32454 f04f78 f68181 fca790 fdcbb0""".split()
# Tonos propios: lo que una ciudad tiene mucho y Resurrect 64 no.
PALETTE += """d2cabd b9b0a3 958c82 6f675f c8b48e a8916c 7d6a50 6e9450 4f7a44 8fae62 a95a48 7e4038""".split()

WARMTH = np.array([1.0, 1.0, 1.0])  # sin tinte: el filtro de ánimo ya calienta la imagen
CONTRAST = 1.04
SATURATION = 0.8  # Kenney es muy saturado
GREEN_SATURATION = 0.6  # pasto y árboles más gastados, menos "de juguete"
GREEN_SHIFT = -40.0
L_WEIGHT = 1.5  # importa más conservar el brillo que el tono exacto
CHROMA_PENALTY = 1.0  # castiga elegir colores más saturados que el original
# Los celestes (agua, vidrios) solo pueden ir a azules: si no, la paleta los manda a gris.
BLUES = ["4d65b4", "4d9be6", "8fd3ff", "0b8a8f", "c7dcd0"]
BLUE_HUES = (185, 215)
# Los grises lavanda de Kenney (veredas, techos, metal) van solo a grises cálidos.
# Los naranjas fuertes (ladrillo, puertas) siguen siendo naranjas: si no, caen en beige.
ORANGES = ["cd683d", "e6904e", "9e4539", "f57d4a", "a95a48", "7e4038", "fbb954", "6e2727"]
WARM_GREYS = ["ffffff", "d2cabd", "b9b0a3", "958c82", "6f675f", "625565", "3e3546", "2e222f"]

# Carpetas de originales -> carpeta de salida (Godot ignora las source/ por el .gdignore).
FOLDERS = [
    (Path("assets/tilesets/source"), Path("assets/tilesets")),
    (Path("assets/prologue/source"), Path("assets/prologue")),
]


def to_oklab(rgb):
    c = rgb / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                   [0.2119034982, 0.6806995451, 0.1073969566],
                   [0.0883024619, 0.2817188376, 0.6299787005]])
    m2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468],
                   [1.9779984951, -2.4285922050, 0.4505937099],
                   [0.0259040371, 0.7827717662, -0.8086757660]])
    lms = np.cbrt(c @ m1.T)
    return lms @ m2.T


def shift_greens(rgb):
    """Rota el tono de los verdes-turquesa hacia verde/amarillo, conserva lo demás."""
    out = rgb.copy()
    for i, (r, g, b) in enumerate(rgb):
        h, l, sat = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        deg = h * 360
        if 130 <= deg <= 172 and sat > 0.2:
            h = ((deg + GREEN_SHIFT) % 360) / 360
            sat *= GREEN_SATURATION
        sat *= SATURATION
        out[i] = np.array(colorsys.hls_to_rgb(h, l, sat)) * 255
    return out


def distance(src_lab, pal_lab):
    d = src_lab[:, None, :] - pal_lab[None, :, :]
    dist = L_WEIGHT * d[..., 0] ** 2 + d[..., 1] ** 2 + d[..., 2] ** 2
    src_c = np.hypot(src_lab[:, 1], src_lab[:, 2])[:, None]
    pal_c = np.hypot(pal_lab[:, 1], pal_lab[:, 2])[None, :]
    return dist + CHROMA_PENALTY * np.clip(pal_c - src_c - 0.02, 0, None) ** 2


pal_rgb = np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in PALETTE], dtype=float)
pal_lab = to_oklab(pal_rgb)

for SRC, DST in FOLDERS:
    for src in sorted(SRC.glob("*.png")):
        im = np.array(Image.open(src).convert("RGBA")).astype(float)
        rgb, alpha = im[..., :3], im[..., 3:]
        rgb = np.clip(((rgb * WARMTH) - 128) * CONTRAST + 128, 0, 255)
        flat = rgb.reshape(-1, 3)
        uniq, inv = np.unique(flat.round(), axis=0, return_inverse=True)
        d = distance(to_oklab(shift_greens(uniq)), pal_lab)
        blue_mask = np.array([h in BLUES for h in PALETTE])
        grey_mask = np.array([h in WARM_GREYS for h in PALETTE])
        orange_mask = np.array([h in ORANGES for h in PALETTE])
        for i, (r, g, b) in enumerate(uniq):
            h, l, sat = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if BLUE_HUES[0] <= h * 360 <= BLUE_HUES[1] and sat > 0.4:
                d[i, ~blue_mask] = np.inf
                if l < 0.72:  # agua: un solo azul medio, sin patrón ruidoso
                    d[i, [k for k, h in enumerate(PALETTE) if h not in ("4d65b4", "4d9be6")]] = np.inf
            elif sat < 0.25 and 200 <= h * 360 <= 290:
                d[i, ~grey_mask] = np.inf
            elif sat > 0.45 and 12 <= h * 360 <= 35:
                d[i, ~orange_mask] = np.inf
        mapped = pal_rgb[d.argmin(1)][inv.ravel()].reshape(rgb.shape)
        out = np.concatenate([mapped, alpha], -1).astype(np.uint8)
        Image.fromarray(out).save(DST / src.name)
        print(src.name, "->", DST / src.name, f"({len(uniq)} colores -> {len(np.unique(mapped.reshape(-1,3), axis=0))})")
