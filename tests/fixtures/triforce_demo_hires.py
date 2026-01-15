#!/usr/bin/env python3
"""
Numpy-vectorized version for maximum performance.
Uses pre-computed coordinate grids and vectorized shape masks.
"""

import numpy as np
import math
import time
import sys
import os
import random

# ============================================================================
# STARFIELD (still scalar - sparse so vectorizing doesn't help much)
# ============================================================================

stars = []
star_grid = {}

def init_stars(num_stars=200):
    global stars
    stars = [(random.random(), random.random(),
              random.uniform(0.3, 1.0), random.uniform(1.0, 5.0),
              random.choice(['·', '∙', '*', '✦', '✧', '+']))
             for _ in range(num_stars)]

def build_star_grid(cols, rows):
    global star_grid
    star_grid = {}
    for sx_r, sy_r, bright, twinkle, char in stars:
        star_grid[(int(sx_r * cols), int(sy_r * rows))] = (bright, twinkle, char, int(sx_r * cols))

def get_star_at(x, y, t):
    data = star_grid.get((x, y))
    if data:
        bright, twinkle, char, sx = data
        b = bright * (0.6 + 0.4 * math.sin(t * twinkle + sx * 0.1))
        return (char, b, b, b * 0.9)
    return None

# ============================================================================
# VECTORIZED SHAPE MASKS
# ============================================================================

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

# ============================================================================
# VECTORIZED COLOR FUNCTIONS
# ============================================================================

def plasma_vec(X, Y, t, cols, rows):
    nx = X / cols * 20
    ny = Y / rows * 20

    v1 = np.sin(nx + t)
    v2 = np.sin((ny + t) * 0.5)
    v3 = np.sin((nx + ny + t) * 0.5)

    cx, cy = 10, 10  # center in normalized coords
    d = np.sqrt((nx - cx)**2 + (ny - cy)**2)
    v4 = np.sin(d - t * 2)

    v = (v1 + v2 + v3 + v4) / 4
    hue = (v + 1) / 2 + t * 0.05
    return hsv_to_rgb_vec(hue, 0.85, 0.9)

def hsv_to_rgb_vec(h, s, v):
    """Vectorized HSV to RGB"""
    h = h % 1.0
    i = (h * 6).astype(int)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)

    # Build RGB arrays
    r = np.where(i == 0, v, np.where(i == 1, q, np.where(i == 2, p,
         np.where(i == 3, p, np.where(i == 4, t, v)))))
    g = np.where(i == 0, t, np.where(i == 1, v, np.where(i == 2, v,
         np.where(i == 3, q, np.where(i == 4, p, p)))))
    b = np.where(i == 0, p, np.where(i == 1, p, np.where(i == 2, t,
         np.where(i == 3, v, np.where(i == 4, v, q)))))
    return r, g, b

# ============================================================================
# NAVIER-STOKES (keep scalar - small fixed grid)
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

def get_ns_color_vec(X, Y, t, cx, cy, size):
    """Vectorized fluid color lookup"""
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

# ============================================================================
# MANDELBROT (vectorized)
# ============================================================================

MB_TARGET = (-0.743643887037158704752191506114774, 0.131825904205311970493132056385139)
mb_zoom = 1.0

def mandelbrot_vec(X, Y, t, cx, cy, size):
    global mb_zoom
    aspect = 2.0
    width = 3.0 / mb_zoom
    height = width * aspect

    nx = (X - cx) / size
    ny = (Y - cy) / size * aspect

    c_re = MB_TARGET[0] + nx * width
    c_im = MB_TARGET[1] + ny * height

    z_re = np.zeros_like(c_re)
    z_im = np.zeros_like(c_im)

    max_iter = min(50, int(30 + math.log(mb_zoom + 1) * 5))  # Reduced iterations
    escape_i = np.full(c_re.shape, max_iter, dtype=float)
    escaped = np.zeros(c_re.shape, dtype=bool)

    for i in range(max_iter):
        z_re_sq = z_re * z_re
        z_im_sq = z_im * z_im
        mag_sq = z_re_sq + z_im_sq

        newly_escaped = (mag_sq > 4.0) & ~escaped
        if np.any(newly_escaped):
            log_zn = np.log(mag_sq[newly_escaped]) / 2
            nu = np.log(log_zn / math.log(2)) / math.log(2)
            escape_i[newly_escaped] = i + 1 - nu
            escaped |= newly_escaped

        if np.all(escaped):
            break

        z_im = 2 * z_re * z_im + c_im
        z_re = z_re_sq - z_im_sq + c_re

    hue = (escape_i * 0.03 + t * 0.05) % 1.0
    val = np.where(escaped, np.minimum(1.0, escape_i * 0.02 + 0.4), 0.0)
    return hsv_to_rgb_vec(hue, 0.8, val)

# ============================================================================
# UTILITIES
# ============================================================================

def get_terminal_size():
    try:
        cols, rows = os.get_terminal_size()
        return cols, rows - 1
    except:
        return 80, 24

BG_SPACE = (0.02, 0.02, 0.06)
BG_SPACE_ANSI = "5;5;15"

# ============================================================================
# MAIN
# ============================================================================

def main():
    global mb_zoom

    print("\033[?25l\033[2J", end="", flush=True)
    init_stars(200)

    t = 0.0
    last_size = (0, 0)
    X_grid = Y_grid = None

    # FPS tracking
    frame_times = []
    last_frame_time = time.time()

    try:
        while True:
            cols, rows = get_terminal_size()
            vrows = rows * 2

            # Rebuild grids if size changed
            if (cols, rows) != last_size:
                build_star_grid(cols, rows)
                # Create coordinate grids for vectorized ops
                x_coords = np.arange(cols)
                y_coords = np.arange(vrows)
                X_grid, Y_grid = np.meshgrid(x_coords, y_coords)
                X_grid = X_grid.astype(float)
                Y_grid = Y_grid.astype(float)
                last_size = (cols, rows)

            center_x = cols // 2
            center_y = vrows // 2
            orbit_rx = cols * 0.3
            orbit_ry = vrows * 0.15
            base_size = min(cols, vrows) * 0.56
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
            # Sort by depth
            shape_data.sort(key=lambda s: s[1][2])

            # Update simulations
            ns_add_source(t)
            ns_step()
            mb_zoom *= 1.02
            if mb_zoom > 1e8:
                mb_zoom = 1.0

            # Initialize RGB arrays with background
            R = np.full((vrows, cols), BG_SPACE[0])
            G = np.full((vrows, cols), BG_SPACE[1])
            B = np.full((vrows, cols), BG_SPACE[2])

            # Occlusion culling: render front-to-back, skip already-filled pixels
            filled = np.zeros((vrows, cols), dtype=bool)

            # Reverse sort: front-to-back (highest depth first)
            for shape_type, (cx, cy, depth, scale) in reversed(shape_data):
                size = base_size * scale

                if shape_type == 'circle':
                    shape_mask = circle_mask(X_grid, Y_grid, cx, cy, size / 2)
                    visible = shape_mask & ~filled  # Only pixels not already covered
                    if np.any(visible):
                        # Only compute colors for visible pixels
                        X_vis, Y_vis = X_grid[visible], Y_grid[visible]
                        r, g, b = get_ns_color_vec(X_vis, Y_vis, t, cx, cy, size)
                        R[visible] = r
                        G[visible] = g
                        B[visible] = b
                        filled |= shape_mask

                elif shape_type == 'square':
                    shape_mask = square_mask(X_grid, Y_grid, cx, cy, size)
                    visible = shape_mask & ~filled
                    if np.any(visible):
                        X_vis, Y_vis = X_grid[visible], Y_grid[visible]
                        r, g, b = plasma_vec(X_vis, Y_vis / 2, t, cols, rows)
                        R[visible] = r
                        G[visible] = g
                        B[visible] = b
                        filled |= shape_mask

                elif shape_type == 'triangle':
                    shape_mask = triangle_mask(X_grid, Y_grid, cx, cy, size)
                    visible = shape_mask & ~filled
                    if np.any(visible):
                        X_vis, Y_vis = X_grid[visible], Y_grid[visible]
                        r, g, b = mandelbrot_vec(X_vis, Y_vis / 2, t, cx, cy / 2, size / 2)
                        R[visible] = r
                        G[visible] = g
                        B[visible] = b
                        filled |= shape_mask

            # Convert to 0-255
            R = (R * 255).astype(int)
            G = (G * 255).astype(int)
            B = (B * 255).astype(int)

            # Build output - combine pairs of rows using half-blocks
            sys.stdout.write("\033[H")
            lines = []

            for row in range(rows):
                y_top = row * 2
                y_bot = row * 2 + 1
                line = []

                for x in range(cols):
                    rt, gt, bt = R[y_top, x], G[y_top, x], B[y_top, x]
                    rb, gb, bb = R[y_bot, x], G[y_bot, x], B[y_bot, x]

                    # Check if both are background (for star chars)
                    is_bg_top = rt == 5 and gt == 5 and bt == 15
                    is_bg_bot = rb == 5 and gb == 5 and bb == 15

                    if is_bg_top and is_bg_bot:
                        star = get_star_at(x, row, t)
                        if star:
                            char, sr, sg, sb = star
                            line.append(f"\033[38;2;{int(sr*255)};{int(sg*255)};{int(sb*255)}m\033[48;2;{BG_SPACE_ANSI}m{char}")
                        else:
                            line.append(f"\033[48;2;{BG_SPACE_ANSI}m ")
                    else:
                        line.append(f"\033[38;2;{rt};{gt};{bt}m\033[48;2;{rb};{gb};{bb}m▀")

                lines.append("".join(line) + "\033[0m")

            # Calculate FPS
            now = time.time()
            frame_times.append(now - last_frame_time)
            last_frame_time = now
            if len(frame_times) > 30:  # Rolling average of last 30 frames
                frame_times.pop(0)
            fps = len(frame_times) / sum(frame_times) if frame_times else 0

            # Overlay FPS on first line (top-right corner)
            fps_str = f" {fps:.1f} fps "
            if len(lines) > 0 and len(lines[0]) > len(fps_str) + 20:
                # Position at top-right: overwrite end of first line
                line0 = lines[0]
                # Find position to insert (account for ANSI codes)
                fps_display = f"\033[1;{cols - len(fps_str)}H\033[48;2;30;30;50m\033[38;2;200;200;255m{fps_str}\033[0m"
            else:
                fps_display = ""

            sys.stdout.write("\r\n".join(lines))
            sys.stdout.write(fps_display)
            sys.stdout.flush()

            t += 0.1
            time.sleep(0.02)

    except KeyboardInterrupt:
        pass
    finally:
        print("\033[?25h\033[0m\033[2J\033[H", end="", flush=True)

if __name__ == "__main__":
    main()
