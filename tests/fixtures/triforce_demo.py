#!/usr/bin/env python3
"""
Three simulations masked by shapes:
  Circle   = Plasma effect
  Square   = Navier-Stokes fluid
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

stars = []  # List of (x_ratio, y_ratio, brightness, twinkle_speed, size)

def init_stars(num_stars=150):
    global stars
    stars = []
    for _ in range(num_stars):
        stars.append((
            random.random(),           # x position (0-1 ratio)
            random.random(),           # y position (0-1 ratio)
            random.uniform(0.3, 1.0),  # base brightness
            random.uniform(1.0, 5.0),  # twinkle speed
            random.choice(['·', '∙', '*', '✦', '✧', '+'])  # star char
        ))

def get_star_at(x, y, cols, rows, t):
    """Check if there's a star at this position and return its color"""
    for sx_r, sy_r, bright, twinkle, char in stars:
        sx = int(sx_r * cols)
        sy = int(sy_r * rows)
        if sx == x and sy == y:
            # Twinkling effect
            b = bright * (0.6 + 0.4 * math.sin(t * twinkle + sx * 0.1))
            return char, b, b, b * 0.9  # Slightly blue-white tint
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
    # Equilateral triangle pointing up
    h = size * 0.866  # height = size * sqrt(3)/2
    # Vertices
    top = (cx, cy - h * 0.6)
    left = (cx - size/2, cy + h * 0.4)
    right = (cx + size/2, cy + h * 0.4)

    def sign(p1, p2, p3):
        return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])

    d1 = sign((x, y), top, left)
    d2 = sign((x, y), left, right)
    d3 = sign((x, y), right, top)

    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

    return not (has_neg and has_pos)

# ============================================================================
# PLASMA EFFECT
# ============================================================================

def plasma(x, y, t, cols, rows):
    # Normalize coordinates
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
# NAVIER-STOKES (simplified for performance)
# ============================================================================

NS_N = 32
ns_u = [0.0] * ((NS_N+2) * (NS_N+2))
ns_v = [0.0] * ((NS_N+2) * (NS_N+2))
ns_dens = [0.0] * ((NS_N+2) * (NS_N+2))

def ns_IX(x, y):
    return int(x) + int(y) * (NS_N + 2)

def ns_add_source(t):
    global ns_dens, ns_u, ns_v
    # Rotating emitter
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
    # Simplified advection
    new_dens = [0.0] * len(ns_dens)
    dt = 0.1

    for j in range(1, NS_N+1):
        for i in range(1, NS_N+1):
            idx = ns_IX(i, j)
            # Trace back
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

    # Decay and add vortex
    cx, cy = NS_N//2, NS_N//2
    for j in range(1, NS_N+1):
        for i in range(1, NS_N+1):
            idx = ns_IX(i, j)
            ns_dens[idx] *= 0.99
            # Vortex
            dx, dy = i - cx, j - cy
            dist = math.sqrt(dx*dx + dy*dy) + 0.1
            if dist < NS_N * 0.4:
                strength = 0.3 * (1 - dist / (NS_N * 0.4))
                ns_u[idx] += -dy / dist * strength
                ns_v[idx] += dx / dist * strength
            # Dampen velocity
            ns_u[idx] *= 0.98
            ns_v[idx] *= 0.98

def get_ns_color(x, y, t, shape_cx, shape_cy, shape_size):
    # Map screen coords to NS grid
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

    # Map screen coords to complex plane
    aspect = 2.0
    width = 3.0 / mb_zoom
    height = width * aspect

    # Normalize within shape
    nx = (x - shape_cx) / shape_size
    ny = (y - shape_cy) / shape_size * aspect

    c_re = MB_TARGET[0] + nx * width
    c_im = MB_TARGET[1] + ny * height

    # Iterate
    z_re, z_im = 0.0, 0.0
    max_iter = min(100, int(50 + math.log(mb_zoom + 1) * 10))

    for i in range(max_iter):
        z_re_sq = z_re * z_re
        z_im_sq = z_im * z_im

        if z_re_sq + z_im_sq > 4.0:
            # Smooth coloring
            log_zn = math.log(z_re_sq + z_im_sq) / 2
            nu = math.log(log_zn / math.log(2)) / math.log(2)
            smooth_i = i + 1 - nu

            hue = (smooth_i * 0.03 + t * 0.05) % 1.0
            return hsv_to_rgb(hue, 0.8, min(1.0, smooth_i * 0.02 + 0.4))

        z_im = 2 * z_re * z_im + c_im
        z_re = z_re_sq - z_im_sq + c_re

    return (0, 0, 0)  # Inside set = black

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

def rgb_bg(r, g, b):
    return f"\033[48;2;{int(r*255)};{int(g*255)};{int(b*255)}m"

# ============================================================================
# MAIN
# ============================================================================

def main():
    global mb_zoom

    print("\033[?25l\033[2J", end="", flush=True)

    # Initialize starfield
    init_stars(200)

    t = 0.0

    try:
        while True:
            cols, rows = get_terminal_size()

            # Carousel effect - ellipse with depth scaling
            center_x = cols // 2
            center_y = rows // 2

            # Ellipse radii (wider than tall for carousel look)
            orbit_rx = cols * 0.3   # horizontal radius
            orbit_ry = rows * 0.15  # vertical radius (smaller = more "flat" carousel)

            # Base shape size
            base_size = min(cols, rows * 2) * 0.56

            # Rotation angle
            rot = t * 0.24

            # Calculate 3D-like positions for each shape
            # depth: -1 (far/top) to +1 (near/bottom)
            def get_carousel_pos(angle):
                x = center_x + orbit_rx * math.cos(angle)
                y = center_y + orbit_ry * math.sin(angle)
                depth = math.sin(angle)  # -1 at top, +1 at bottom
                # Scale based on depth (bigger when closer)
                scale = 0.25 + 0.75 * (depth + 1) / 2  # 0.25 to 1.0
                return x, y, depth, scale

            # Get positions for all three shapes
            circle_x, circle_y, circle_depth, circle_scale = get_carousel_pos(rot)
            square_x, square_y, square_depth, square_scale = get_carousel_pos(rot + 2.094)
            tri_x, tri_y, tri_depth, tri_scale = get_carousel_pos(rot + 4.189)

            # Calculate sizes based on depth
            circle_r = base_size * circle_scale / 2
            circle_cx, circle_cy = circle_x, circle_y

            shape_size = base_size * square_scale
            square_cx, square_cy = square_x, square_y

            tri_base = base_size * tri_scale
            tri_cx, tri_cy = tri_x, tri_y

            # Sort shapes by depth (back to front)
            shapes = [
                ('circle', circle_depth, circle_cx, circle_cy, circle_r, circle_scale),
                ('square', square_depth, square_cx, square_cy, shape_size, square_scale),
                ('triangle', tri_depth, tri_cx, tri_cy, tri_base, tri_scale),
            ]
            shapes.sort(key=lambda s: s[1])  # Sort by depth (render far ones first)

            # Update simulations
            ns_add_source(t)
            ns_step()
            mb_zoom *= 1.02
            if mb_zoom > 1e8:
                mb_zoom = 1.0

            # Render
            sys.stdout.write("\033[H")

            lines = []
            for y in range(rows):
                row = []
                for x in range(cols):
                    # Check shapes in depth order (back to front)
                    pixel_set = False
                    r, g, b = 0, 0, 0

                    # Iterate through sorted shapes (back to front)
                    for shape_type, depth, cx, cy, size, scale in shapes:
                        if shape_type == 'circle':
                            if in_circle(x, y * 2, cx, cy * 2, size):
                                r, g, b = get_ns_color(x, y * 2, t, cx, cy * 2, size * 2)
                                pixel_set = True
                        elif shape_type == 'square':
                            if in_square(x, y * 2, cx, cy * 2, size):
                                r, g, b = plasma(x, y, t, cols, rows)
                                pixel_set = True
                        elif shape_type == 'triangle':
                            if in_triangle(x, y * 2, cx, cy * 2, size):
                                r, g, b = mandelbrot_color(x, y, t, cx, cy, size / 2)
                                pixel_set = True

                    if pixel_set:
                        row.append(f"{rgb_bg(r, g, b)} ")
                    else:
                        # Starfield background
                        star = get_star_at(x, y, cols, rows, t)
                        if star:
                            char, sr, sg, sb = star
                            row.append(f"\033[48;2;5;5;15m\033[38;2;{int(sr*255)};{int(sg*255)};{int(sb*255)}m{char}")
                        else:
                            row.append("\033[48;2;5;5;15m ")

                lines.append("".join(row) + "\033[0m")

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
