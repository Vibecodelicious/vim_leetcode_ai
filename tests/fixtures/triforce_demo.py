#!/usr/bin/env python3
"""
High-resolution version using UTF-8 half-block characters (▀)
to double vertical resolution.

Three simulations masked by shapes:
  Circle   = Fluid simulation
  Square   = Plasma effect
  Triangle = Mandelbrot zoom
"""

import math
import time
import sys
import os
import random

# ============================================================================
# STARFIELD
# ============================================================================

stars = []
star_grid = {}  # (cols, rows) -> {(x,y): (bright, twinkle, char)}

def init_stars(num_stars=150):
    global stars
    stars = []
    for _ in range(num_stars):
        stars.append((
            random.random(),
            random.random(),
            random.uniform(0.3, 1.0),
            random.uniform(1.0, 5.0),
            random.choice(['·', '∙', '*', '✦', '✧', '+'])
        ))

def build_star_grid(cols, rows):
    """Build a dict for O(1) star lookup"""
    global star_grid
    grid = {}
    for sx_r, sy_r, bright, twinkle, char in stars:
        sx = int(sx_r * cols)
        sy = int(sy_r * rows)
        grid[(sx, sy)] = (bright, twinkle, char, sx)
    star_grid = grid

def get_star_at(x, y, t):
    """O(1) star lookup"""
    data = star_grid.get((x, y))
    if data:
        bright, twinkle, char, sx = data
        b = bright * (0.6 + 0.4 * math.sin(t * twinkle + sx * 0.1))
        return (char, b, b, b * 0.9)
    return None

# ============================================================================
# SHAPE MASKS
# ============================================================================

def in_circle(x, y, cx, cy, r):
    return (x - cx)**2 + (y - cy)**2 <= r**2

def in_square(x, y, cx, cy, size):
    half = size / 2
    return abs(x - cx) <= half and abs(y - cy) <= half

def in_triangle(x, y, cx, cy, size):
    h = size * 0.866
    # Vertices
    top_x, top_y = cx, cy - h * 0.6
    left_x, left_y = cx - size * 0.5, cy + h * 0.4
    right_x, right_y = cx + size * 0.5, cy + h * 0.4

    # Inline sign calculations
    d1 = (x - left_x) * (top_y - left_y) - (top_x - left_x) * (y - left_y)
    d2 = (x - right_x) * (left_y - right_y) - (left_x - right_x) * (y - right_y)
    d3 = (x - top_x) * (right_y - top_y) - (right_x - top_x) * (y - top_y)

    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

    return not (has_neg and has_pos)

# ============================================================================
# PLASMA EFFECT
# ============================================================================

def plasma(x, y, t, cols, rows):
    nx = x / cols * 20
    ny = y / rows * 20

    v1 = math.sin(nx + t)
    v2 = math.sin((ny + t) * 0.5)
    v3 = math.sin((nx + ny + t) * 0.5)

    cx, cy = cols/2 / cols * 20, rows/2 / rows * 20
    d = math.sqrt((nx - cx)**2 + (ny - cy)**2)
    v4 = math.sin(d - t * 2)

    v = (v1 + v2 + v3 + v4) / 4

    hue = (v + 1) / 2 + t * 0.05
    return hsv_to_rgb(hue, 0.85, 0.9)

# ============================================================================
# NAVIER-STOKES (simplified)
# ============================================================================

NS_N = 32
ns_u = [0.0] * ((NS_N+2) * (NS_N+2))
ns_v = [0.0] * ((NS_N+2) * (NS_N+2))
ns_dens = [0.0] * ((NS_N+2) * (NS_N+2))

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
                if 0 <= idx < len(ns_dens):
                    ns_dens[idx] += 0.3

        vx = -math.sin(angle) * 30
        vy = math.cos(angle) * 30
        idx = ns_IX(cx, cy)
        if 0 <= idx < len(ns_u):
            ns_u[idx] += vx * 0.1
            ns_v[idx] += vy * 0.1

def ns_step():
    global ns_dens, ns_u, ns_v
    new_dens = [0.0] * len(ns_dens)
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

            if 0 <= ns_IX(i0, j0) < len(ns_dens) and 0 <= ns_IX(i0+1, j0+1) < len(ns_dens):
                new_dens[idx] = (1-s) * ((1-t_val) * ns_dens[ns_IX(i0, j0)] + t_val * ns_dens[ns_IX(i0, j0+1)]) + \
                                s * ((1-t_val) * ns_dens[ns_IX(i0+1, j0)] + t_val * ns_dens[ns_IX(i0+1, j0+1)])

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

def get_ns_color(x, y, t, shape_cx, shape_cy, shape_size):
    gx = int(1 + (x - shape_cx + shape_size/2) / shape_size * NS_N)
    gy = int(1 + (y - shape_cy + shape_size/2) / shape_size * NS_N)

    gx = max(1, min(NS_N, gx))
    gy = max(1, min(NS_N, gy))

    d = ns_dens[ns_IX(gx, gy)]
    hue = (d * 0.5 + t * 0.03) % 1.0
    sat = min(1.0, d * 2 + 0.3)
    val = min(1.0, d * 1.5 + 0.1)

    return hsv_to_rgb(hue, sat, val)

# ============================================================================
# MANDELBROT
# ============================================================================

MB_TARGET = (-0.743643887037158704752191506114774, 0.131825904205311970493132056385139)
mb_zoom = 1.0

def mandelbrot_color(x, y, t, shape_cx, shape_cy, shape_size):
    global mb_zoom

    aspect = 2.0
    width = 3.0 / mb_zoom
    height = width * aspect

    nx = (x - shape_cx) / shape_size
    ny = (y - shape_cy) / shape_size * aspect

    c_re = MB_TARGET[0] + nx * width
    c_im = MB_TARGET[1] + ny * height

    z_re, z_im = 0.0, 0.0
    max_iter = min(100, int(50 + math.log(mb_zoom + 1) * 10))

    for i in range(max_iter):
        z_re_sq = z_re * z_re
        z_im_sq = z_im * z_im

        if z_re_sq + z_im_sq > 4.0:
            log_zn = math.log(z_re_sq + z_im_sq) / 2
            nu = math.log(log_zn / math.log(2)) / math.log(2)
            smooth_i = i + 1 - nu

            hue = (smooth_i * 0.03 + t * 0.05) % 1.0
            return hsv_to_rgb(hue, 0.8, min(1.0, smooth_i * 0.02 + 0.4))

        z_im = 2 * z_re * z_im + c_im
        z_re = z_re_sq - z_im_sq + c_re

    return (0, 0, 0)

# ============================================================================
# UTILITIES
# ============================================================================

def get_terminal_size():
    try:
        cols, rows = os.get_terminal_size()
        return cols, rows - 1
    except:
        return 80, 24

def hsv_to_rgb(h, s, v):
    h = h % 1.0
    i = int(h * 6)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    if i == 0: return v, t, p
    elif i == 1: return q, v, p
    elif i == 2: return p, v, t
    elif i == 3: return p, q, v
    elif i == 4: return t, p, v
    else: return v, p, q

def rgb_to_ansi(r, g, b):
    return f"{int(r*255)};{int(g*255)};{int(b*255)}"

# Background color for stars/space
BG_SPACE = (0.02, 0.02, 0.06)
BG_SPACE_ANSI = "5;5;15"  # Pre-computed ANSI string

# ============================================================================
# PIXEL SAMPLING
# ============================================================================

def get_shape_color(x, y, t, cols, vrows, shapes):
    """Get shape color at virtual pixel (x, y), or None if no shape covers it.
    Shapes are sorted back-to-front, so iterate all and let last match win."""
    color = None
    for shape_type, depth, cx, cy, size, scale in shapes:
        if shape_type == 'circle':
            if in_circle(x, y, cx, cy, size):
                color = get_ns_color(x, y, t, cx, cy, size * 2)
        elif shape_type == 'square':
            if in_square(x, y, cx, cy, size):
                color = plasma(x, y / 2, t, cols, vrows // 2)
        elif shape_type == 'triangle':
            if in_triangle(x, y, cx, cy, size):
                color = mandelbrot_color(x, y / 2, t, cx, cy / 2, size / 2)
    return color

# ============================================================================
# MAIN - HIGH RESOLUTION VERSION
# ============================================================================

def main():
    global mb_zoom

    print("\033[?25l\033[2J", end="", flush=True)
    init_stars(200)

    t = 0.0
    last_size = (0, 0)

    try:
        while True:
            cols, rows = get_terminal_size()

            # Rebuild star grid if terminal size changed
            if (cols, rows) != last_size:
                build_star_grid(cols, rows)
                last_size = (cols, rows)

            vrows = rows * 2  # Virtual rows (2x resolution)

            center_x = cols // 2
            center_y = vrows // 2  # Center in virtual space

            orbit_rx = cols * 0.3
            orbit_ry = vrows * 0.15

            base_size = min(cols, vrows) * 0.56

            rot = t * 0.24

            def get_carousel_pos(angle):
                x = center_x + orbit_rx * math.cos(angle)
                y = center_y + orbit_ry * math.sin(angle)
                depth = math.sin(angle)
                scale = 0.25 + 1.75 * (depth + 1) / 2  # 0.25 (far) to 2.0 (near)
                return x, y, depth, scale

            circle_x, circle_y, circle_depth, circle_scale = get_carousel_pos(rot)
            square_x, square_y, square_depth, square_scale = get_carousel_pos(rot + 2.094)
            tri_x, tri_y, tri_depth, tri_scale = get_carousel_pos(rot + 4.189)

            circle_r = base_size * circle_scale / 2
            shape_size = base_size * square_scale
            tri_base = base_size * tri_scale

            shapes = [
                ('circle', circle_depth, circle_x, circle_y, circle_r, circle_scale),
                ('square', square_depth, square_x, square_y, shape_size, square_scale),
                ('triangle', tri_depth, tri_x, tri_y, tri_base, tri_scale),
            ]
            shapes.sort(key=lambda s: s[1])

            ns_add_source(t)
            ns_step()
            mb_zoom *= 1.02
            if mb_zoom > 1e8:
                mb_zoom = 1.0

            sys.stdout.write("\033[H")

            lines = []
            for row in range(rows):
                line = []
                y_top = row * 2      # Virtual y for top half
                y_bot = row * 2 + 1  # Virtual y for bottom half

                for x in range(cols):
                    # Check shapes at virtual resolution (2x)
                    c_top = get_shape_color(x, y_top, t, cols, vrows, shapes)
                    c_bot = get_shape_color(x, y_bot, t, cols, vrows, shapes)

                    # Both pixels are background - can use star characters
                    if c_top is None and c_bot is None:
                        star = get_star_at(x, row, t)
                        if star:
                            char, sr, sg, sb = star
                            line.append(f"\033[38;2;{int(sr*255)};{int(sg*255)};{int(sb*255)}m\033[48;2;{BG_SPACE_ANSI}m{char}")
                        else:
                            line.append(f"\033[48;2;{BG_SPACE_ANSI}m ")
                    else:
                        # At least one pixel has a shape - use half-block
                        if c_top is None:
                            c_top = BG_SPACE
                        if c_bot is None:
                            c_bot = BG_SPACE
                        line.append(f"\033[38;2;{int(c_top[0]*255)};{int(c_top[1]*255)};{int(c_top[2]*255)}m\033[48;2;{int(c_bot[0]*255)};{int(c_bot[1]*255)};{int(c_bot[2]*255)}m▀")

                lines.append("".join(line) + "\033[0m")

            sys.stdout.write("\r\n".join(lines))
            sys.stdout.flush()

            t += 0.1
            time.sleep(0.03)

    except KeyboardInterrupt:
        pass
    finally:
        print("\033[?25h\033[0m\033[2J\033[H", end="", flush=True)

if __name__ == "__main__":
    main()
