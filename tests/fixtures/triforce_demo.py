#!/usr/bin/env python3
"""
Braille character version - 2x4 dots per character = 8x resolution!

Braille Unicode block U+2800-U+28FF:
  Each character is a 2x4 grid of dots:
    ⠁⠂⠄⡀    Bit positions:
    ⠈⠐⠠⢀    0 3
    ⣀⣄⣤⣴    1 4
    ⣿⣶⣤⣀    2 5
               6 7
"""

import numpy as np
import math
import time
import sys
import os
import random

# ============================================================================
# BRAILLE ENCODING
# ============================================================================

# Braille dot positions (2 cols x 4 rows):
#   0 3
#   1 4
#   2 5
#   6 7
BRAILLE_BASE = 0x2800

def encode_braille_char(dots):
    """Convert 2x4 boolean array to braille character.
    dots[row][col] where row 0-3, col 0-1"""
    code = 0
    if dots[0, 0]: code |= 0x01
    if dots[1, 0]: code |= 0x02
    if dots[2, 0]: code |= 0x04
    if dots[0, 1]: code |= 0x08
    if dots[1, 1]: code |= 0x10
    if dots[2, 1]: code |= 0x20
    if dots[3, 0]: code |= 0x40
    if dots[3, 1]: code |= 0x80
    return chr(BRAILLE_BASE + code)

# ============================================================================
# VECTORIZED HELPERS
# ============================================================================

def hsv_to_rgb_vec(h, s, v):
    h = h % 1.0
    i = (h * 6).astype(int)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    r = np.where(i == 0, v, np.where(i == 1, q, np.where(i == 2, p,
         np.where(i == 3, p, np.where(i == 4, t, v)))))
    g = np.where(i == 0, t, np.where(i == 1, v, np.where(i == 2, v,
         np.where(i == 3, q, np.where(i == 4, p, p)))))
    b = np.where(i == 0, p, np.where(i == 1, p, np.where(i == 2, t,
         np.where(i == 3, v, np.where(i == 4, v, q)))))
    return r, g, b

def circle_mask(X, Y, cx, cy, r):
    return (X - cx)**2 + (Y - cy)**2 <= r**2

def square_mask(X, Y, cx, cy, size):
    half = size / 2
    return (np.abs(X - cx) <= half) & (np.abs(Y - cy) <= half)

def triangle_mask(X, Y, cx, cy, size):
    h = size * 0.866
    top_x, top_y = cx, cy - h * 0.6
    left_x, left_y = cx - size * 0.5, cy + h * 0.4
    right_x, right_y = cx + size * 0.5, cy + h * 0.4
    d1 = (X - left_x) * (top_y - left_y) - (top_x - left_x) * (Y - left_y)
    d2 = (X - right_x) * (left_y - right_y) - (left_x - right_x) * (Y - right_y)
    d3 = (X - top_x) * (right_y - top_y) - (right_x - top_x) * (Y - top_y)
    has_neg = (d1 < 0) | (d2 < 0) | (d3 < 0)
    has_pos = (d1 > 0) | (d2 > 0) | (d3 > 0)
    return ~(has_neg & has_pos)

def plasma_vec(X, Y, t, cols, rows):
    nx = X / cols * 20
    ny = Y / rows * 20
    v1 = np.sin(nx + t)
    v2 = np.sin((ny + t) * 0.5)
    v3 = np.sin((nx + ny + t) * 0.5)
    d = np.sqrt((nx - 10)**2 + (ny - 10)**2)
    v4 = np.sin(d - t * 2)
    v = (v1 + v2 + v3 + v4) / 4
    hue = (v + 1) / 2 + t * 0.05
    return hsv_to_rgb_vec(hue, 0.85, 0.9)

# ============================================================================
# NAVIER-STOKES FLUID SIMULATION
# ============================================================================

NS_N = 32
NS_SIZE = (NS_N + 2) ** 2
ns_u = np.zeros(NS_SIZE)
ns_v = np.zeros(NS_SIZE)
ns_dens = np.zeros(NS_SIZE)

def ns_IX(x, y):
    return int(x) + int(y) * (NS_N + 2)

def ns_add_source(t):
    global ns_dens, ns_u, ns_v
    for k in range(2):
        angle = t * (0.8 + k * 0.5) + k * 3.14
        cx = NS_N//2 + int(math.cos(angle) * NS_N * 0.25)
        cy = NS_N//2 + int(math.sin(angle) * NS_N * 0.25)
        for di in range(-1, 2):
            for dj in range(-1, 2):
                idx = ns_IX(cx + di, cy + dj)
                if 0 <= idx < NS_SIZE:
                    ns_dens[idx] += 0.3
        vx = -math.sin(angle) * 30
        vy = math.cos(angle) * 30
        idx = ns_IX(cx, cy)
        if 0 <= idx < NS_SIZE:
            ns_u[idx] += vx * 0.1
            ns_v[idx] += vy * 0.1

def ns_step():
    global ns_dens, ns_u, ns_v
    new_dens = np.zeros(NS_SIZE)
    dt = 0.1
    for j in range(1, NS_N+1):
        for i in range(1, NS_N+1):
            idx = ns_IX(i, j)
            x = i - dt * NS_N * ns_u[idx] * 0.1
            y = j - dt * NS_N * ns_v[idx] * 0.1
            x = max(0.5, min(NS_N + 0.5, x))
            y = max(0.5, min(NS_N + 0.5, y))
            i0, j0 = int(x), int(y)
            s, t_val = x - i0, y - j0
            idx00, idx01 = ns_IX(i0, j0), ns_IX(i0, j0+1)
            idx10, idx11 = ns_IX(i0+1, j0), ns_IX(i0+1, j0+1)
            if 0 <= idx00 < NS_SIZE and 0 <= idx11 < NS_SIZE:
                new_dens[idx] = ((1-s) * ((1-t_val) * ns_dens[idx00] + t_val * ns_dens[idx01]) +
                                 s * ((1-t_val) * ns_dens[idx10] + t_val * ns_dens[idx11]))
    ns_dens = new_dens
    cx, cy = NS_N//2, NS_N//2
    for j in range(1, NS_N+1):
        for i in range(1, NS_N+1):
            idx = ns_IX(i, j)
            ns_dens[idx] *= 0.99
            dx, dy = i - cx, j - cy
            dist = math.sqrt(dx*dx + dy*dy) + 0.1
            if dist < NS_N * 0.4:
                strength = 0.3 * (1 - dist / (NS_N * 0.4))
                ns_u[idx] += -dy / dist * strength
                ns_v[idx] += dx / dist * strength
            ns_u[idx] *= 0.98
            ns_v[idx] *= 0.98

def fluid_vec(X, Y, t, cx, cy, size):
    """Vectorized fluid color lookup from Navier-Stokes grid"""
    gx = (1 + (X - cx + size/2) / size * NS_N).astype(int)
    gy = (1 + (Y - cy + size/2) / size * NS_N).astype(int)
    gx = np.clip(gx, 1, NS_N)
    gy = np.clip(gy, 1, NS_N)
    idx = gx + gy * (NS_N + 2)
    d = ns_dens[idx]
    hue = (d * 0.5 + t * 0.03) % 1.0
    sat = np.minimum(1.0, d * 2 + 0.3)
    val = np.minimum(1.0, d * 1.5 + 0.1)
    return hsv_to_rgb_vec(hue, sat, val)

MB_TARGET = (-0.743643887037158704752191506114774, 0.131825904205311970493132056385139)
mb_zoom = 1.0

def mandelbrot_vec(X, Y, t, cx, cy, size):
    global mb_zoom
    width = 3.0 / mb_zoom
    nx = (X - cx) / size
    ny = (Y - cy) / size
    c_re = MB_TARGET[0] + nx * width
    c_im = MB_TARGET[1] + ny * width
    z_re = np.zeros_like(c_re)
    z_im = np.zeros_like(c_im)
    max_iter = min(35, int(20 + math.log(mb_zoom + 1) * 4))
    escape_i = np.full(c_re.shape, max_iter, dtype=float)
    escaped = np.zeros(c_re.shape, dtype=bool)
    for i in range(max_iter):
        z_re = np.clip(z_re, -1e10, 1e10)
        z_im = np.clip(z_im, -1e10, 1e10)
        z_re_sq = z_re * z_re
        z_im_sq = z_im * z_im
        mag_sq = z_re_sq + z_im_sq
        newly_escaped = (mag_sq > 4.0) & ~escaped
        if np.any(newly_escaped):
            safe_mag = np.maximum(mag_sq[newly_escaped], 1e-10)
            log_zn = np.log(safe_mag) / 2
            nu = np.log(np.maximum(log_zn / math.log(2), 1e-10)) / math.log(2)
            escape_i[newly_escaped] = i + 1 - nu
            escaped |= newly_escaped
        if np.all(escaped):
            break
        z_im_new = 2 * z_re * z_im + c_im
        z_re = z_re_sq - z_im_sq + c_re
        z_im = z_im_new
    hue = (escape_i * 0.03 + t * 0.05) % 1.0
    val = np.where(escaped, np.minimum(1.0, escape_i * 0.02 + 0.4), 0.0)
    return hsv_to_rgb_vec(hue, 0.8, val)

# ============================================================================
# MAIN
# ============================================================================

def get_terminal_size():
    try:
        cols, rows = os.get_terminal_size()
        return cols, rows - 1
    except:
        return 80, 24

BG_COLOR = (0.02, 0.02, 0.06)

def main():
    global mb_zoom

    print("\033[?25l\033[2J", end="", flush=True)

    t = 0.0
    last_size = (0, 0)
    X_grid = Y_grid = None
    frame_times = []
    last_frame_time = time.time()

    # Stars stored as dict: (char_col, char_row) -> (char, brightness, twinkle_speed)
    star_chars = {}
    STAR_GLYPHS = ['·', '∙', '*', '✦', '✧', '+']

    try:
        while True:
            cols, rows = get_terminal_size()

            # Virtual resolution: 2x width, 4x height (braille is 2x4)
            vwidth = cols * 2
            vheight = rows * 4

            if (cols, rows) != last_size:
                # Rebuild coordinate grids
                x_coords = np.arange(vwidth, dtype=float)
                y_coords = np.arange(vheight, dtype=float)
                X_grid, Y_grid = np.meshgrid(x_coords, y_coords)

                # Generate stars at character cell positions
                star_chars = {}
                for _ in range(200):
                    sc, sr = random.randint(0, cols-1), random.randint(0, rows-1)
                    star_chars[(sc, sr)] = (
                        random.choice(STAR_GLYPHS),
                        random.uniform(0.4, 1.0),
                        random.uniform(1.0, 5.0)
                    )

                last_size = (cols, rows)

            center_x = vwidth // 2
            center_y = vheight // 2
            orbit_rx = vwidth * 0.3
            orbit_ry = vheight * 0.15
            base_size = min(vwidth, vheight) * 0.5
            rot = t * 0.24

            def get_carousel_pos(angle):
                x = center_x + orbit_rx * math.cos(angle)
                y = center_y + orbit_ry * math.sin(angle)
                depth = math.sin(angle)
                scale = 0.25 + 1.75 * (depth + 1) / 2
                return x, y, depth, scale

            positions = [get_carousel_pos(rot + i * 2.094) for i in range(3)]
            shape_data = [
                ('circle', positions[0]),
                ('square', positions[1]),
                ('triangle', positions[2]),
            ]
            shape_data.sort(key=lambda s: s[1][2])

            mb_zoom *= 1.02
            if mb_zoom > 2.5e7:  # 1/4 of original max depth
                mb_zoom = 1.0

            # Update Navier-Stokes fluid simulation
            ns_add_source(t)
            ns_step()

            # RGB arrays
            R = np.full((vheight, vwidth), BG_COLOR[0])
            G = np.full((vheight, vwidth), BG_COLOR[1])
            B = np.full((vheight, vwidth), BG_COLOR[2])

            # Occlusion culling: front-to-back
            filled = np.zeros((vheight, vwidth), dtype=bool)

            for shape_type, (cx, cy, depth, scale) in reversed(shape_data):
                size = base_size * scale

                if shape_type == 'circle':
                    shape_mask = circle_mask(X_grid, Y_grid, cx, cy, size / 2)
                elif shape_type == 'square':
                    shape_mask = square_mask(X_grid, Y_grid, cx, cy, size)
                elif shape_type == 'triangle':
                    shape_mask = triangle_mask(X_grid, Y_grid, cx, cy, size)

                visible = shape_mask & ~filled
                if np.any(visible):
                    X_vis, Y_vis = X_grid[visible], Y_grid[visible]

                    if shape_type == 'circle':
                        r, g, b = fluid_vec(X_vis, Y_vis, t, cx, cy, size)
                    elif shape_type == 'square':
                        r, g, b = plasma_vec(X_vis, Y_vis, t, vwidth, vheight)
                    elif shape_type == 'triangle':
                        r, g, b = mandelbrot_vec(X_vis, Y_vis, t, cx, cy, size / 2)

                    R[visible] = r
                    G[visible] = g
                    B[visible] = b
                    filled |= shape_mask

            # Compute brightness for dot thresholding
            brightness = 0.299 * R + 0.587 * G + 0.114 * B

            # Build output using braille
            sys.stdout.write("\033[H")
            lines = []

            for row in range(rows):
                line_chars = []
                vy_base = row * 4

                for col in range(cols):
                    vx_base = col * 2

                    # Check if this cell has any shape pixels (with bounds checking)
                    vy_end = min(vy_base + 4, vheight)
                    vx_end = min(vx_base + 2, vwidth)
                    if vy_base < vheight and vx_base < vwidth:
                        cell_filled = filled[vy_base:vy_end, vx_base:vx_end]
                        has_shape = np.any(cell_filled)
                    else:
                        has_shape = False

                    if not has_shape:
                        # Background cell - use star character if present
                        star_data = star_chars.get((col, row))
                        if star_data:
                            char, base_bright, twinkle_speed = star_data
                            b = base_bright * (0.6 + 0.4 * math.sin(t * twinkle_speed + col * 0.1))
                            # Blue-white tint for stars
                            sr = int(b * 200)
                            sg = int(b * 220)
                            sb = int(b * 255)
                            line_chars.append(f"\033[48;2;5;5;20m\033[38;2;{sr};{sg};{sb}m{char}")
                        else:
                            line_chars.append(f"\033[48;2;5;5;20m\033[38;2;5;5;20m ")
                    else:
                        # Shape cell - use braille
                        dots = np.zeros((4, 2), dtype=bool)
                        r_sum, g_sum, b_sum = 0.0, 0.0, 0.0
                        count = 0

                        for dy in range(4):
                            for dx in range(2):
                                vy = vy_base + dy
                                vx = vx_base + dx
                                if vy < vheight and vx < vwidth:
                                    if brightness[vy, vx] > 0.25:
                                        dots[dy, dx] = True
                                    r_sum += R[vy, vx]
                                    g_sum += G[vy, vx]
                                    b_sum += B[vy, vx]
                                    count += 1

                        char = encode_braille_char(dots)

                        if count > 0:
                            r_avg = int(min(255, r_sum / count * 255))
                            g_avg = int(min(255, g_sum / count * 255))
                            b_avg = int(min(255, b_sum / count * 255))
                        else:
                            r_avg, g_avg, b_avg = 5, 5, 20

                        line_chars.append(f"\033[48;2;5;5;20m\033[38;2;{r_avg};{g_avg};{b_avg}m{char}")

                lines.append("".join(line_chars) + "\033[0m")

            # FPS
            now = time.time()
            frame_times.append(now - last_frame_time)
            last_frame_time = now
            if len(frame_times) > 30:
                frame_times.pop(0)
            fps = len(frame_times) / sum(frame_times) if frame_times else 0

            sys.stdout.write("\033[48;2;5;5;15m")  # Dark background
            sys.stdout.write("\r\n".join(lines))
            sys.stdout.write(f"\033[1;{cols-12}H\033[48;2;30;30;50m {fps:.1f} fps ")
            sys.stdout.flush()

            t += 0.1
            time.sleep(0.02)

    except KeyboardInterrupt:
        pass
    finally:
        print("\033[?25h\033[0m\033[2J\033[H", end="", flush=True)

if __name__ == "__main__":
    main()
