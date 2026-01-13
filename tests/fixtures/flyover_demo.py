#!/usr/bin/env python3
"""
Demoscene-style terrain flyover using braille characters for 2x4 resolution.
Classic mode-7 style perspective terrain with color cycling.
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

BRAILLE_BASE = 0x2800

def encode_braille_char(dots):
    """Convert 2x4 boolean array to braille character."""
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
# TERRAIN GENERATION
# ============================================================================

def noise2d_vec(x, y, seed=42):
    """Vectorized value noise"""
    n = (x.astype(np.int64) + y.astype(np.int64) * 57 + seed * 131).astype(np.int64)
    n = (n << 13) ^ n
    n = n.astype(np.int64)
    return (1.0 - ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0)

def smoothed_noise_vec(x, y, seed=42):
    """Vectorized interpolated noise"""
    ix = np.floor(x).astype(np.int64)
    iy = np.floor(y).astype(np.int64)
    fx = x - ix
    fy = y - iy

    # Smoothstep
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)

    v00 = noise2d_vec(ix, iy, seed)
    v10 = noise2d_vec(ix + 1, iy, seed)
    v01 = noise2d_vec(ix, iy + 1, seed)
    v11 = noise2d_vec(ix + 1, iy + 1, seed)

    i1 = v00 * (1 - fx) + v10 * fx
    i2 = v01 * (1 - fx) + v11 * fx

    return i1 * (1 - fy) + i2 * fy

def terrain_height_vec(x, z, t):
    """Vectorized terrain height - 3 octaves with lower frequency"""
    h = np.zeros_like(x)
    h += smoothed_noise_vec(x * 0.013 + t * 0.07, z * 0.013, seed=1) * 35
    h += smoothed_noise_vec(x * 0.033, z * 0.033 + t * 0.03, seed=2) * 18
    h += smoothed_noise_vec(x * 0.066, z * 0.066, seed=3) * 8
    h += np.sin(x * 0.02 + t) * 12
    h += np.sin(z * 0.013) * 10
    return h

# ============================================================================
# COLOR UTILITIES
# ============================================================================

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

def terrain_color_vec(height, dist, t):
    """Vectorized color based on height and distance"""
    h_norm = np.clip((height + 50) / 100, 0, 1)
    base_hue = t * 0.05

    # Initialize arrays
    hue = np.zeros_like(height)
    sat = np.zeros_like(height)
    val = np.zeros_like(height)

    # Water/low - blue
    mask = h_norm < 0.3
    hue[mask] = 0.6 + base_hue * 0.2
    sat[mask] = 0.8
    val[mask] = 0.3 + h_norm[mask]

    # Plains - green
    mask = (h_norm >= 0.3) & (h_norm < 0.5)
    hue[mask] = 0.3 + base_hue * 0.1
    sat[mask] = 0.7
    val[mask] = 0.4 + h_norm[mask] * 0.5

    # Hills - yellow/brown
    mask = (h_norm >= 0.5) & (h_norm < 0.7)
    hue[mask] = 0.1 + base_hue * 0.1
    sat[mask] = 0.6
    val[mask] = 0.5 + h_norm[mask] * 0.3

    # Peaks - white/snow
    mask = h_norm >= 0.7
    hue[mask] = 0.6
    sat[mask] = 0.1
    val[mask] = 0.8 + h_norm[mask] * 0.2

    # Distance fog
    fog = np.minimum(1, dist / 500)
    val = val * (1 - fog * 0.7)
    sat = sat * (1 - fog * 0.5)

    return hsv_to_rgb_vec(hue, sat, val)

def hsv_to_rgb_vec(h, s, v):
    """Vectorized HSV to RGB"""
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

# ============================================================================
# STARFIELD
# ============================================================================

def init_stars(cols, rows, num=150):
    stars = {}
    glyphs = ['·', '∙', '*', '✦', '✧', '+', '°']
    for _ in range(num):
        c, r = random.randint(0, cols-1), random.randint(0, int(rows * 0.6))  # Upper 60% for tilted horizon
        stars[(c, r)] = (random.choice(glyphs), random.uniform(0.4, 1.0), random.uniform(1, 5))
    return stars

# ============================================================================
# MAIN RENDERER
# ============================================================================

def get_terminal_size():
    try:
        cols, rows = os.get_terminal_size()
        return cols, rows - 1
    except:
        return 80, 24

def main():
    print("\033[?25l\033[2J", end="", flush=True)

    t = 0.0
    last_size = (0, 0)
    stars = {}
    frame_times = []
    last_frame_time = time.time()

    # Camera state
    cam_x = 0.0
    cam_z = 0.0
    cam_y = 80.0  # Height above terrain
    cam_speed = 5.0
    cam_yaw = 0.0  # Current heading angle

    try:
        while True:
            cols, rows = get_terminal_size()
            vwidth = cols * 2
            vheight = rows * 4

            if (cols, rows) != last_size:
                stars = init_stars(cols, rows, 200)
                last_size = (cols, rows)

            # Glider physics - smooth oscillating pitch and bank (1.5x amplitude)
            # Pitch: nose up/down
            pitch_input = math.sin(t * 0.4) * 0.75 + math.sin(t * 0.17) * 0.45
            pitch = -0.2 + pitch_input * 0.225  # Base pitch + variation

            # Bank/yaw: turning left/right
            bank_input = math.sin(t * 0.23) * 1.05 + math.sin(t * 0.11) * 0.6
            bank = bank_input * 0.6  # Bank angle affects turn rate

            # Update yaw (heading) based on bank - banking turns the glider
            cam_yaw += bank * 0.03

            # Move in the direction we're facing
            cam_z += math.cos(cam_yaw) * cam_speed
            cam_x += math.sin(cam_yaw) * cam_speed

            # Pitch affects altitude - nose up = climb, nose down = dive
            cam_y += pitch * 12
            cam_y = max(30, min(175, cam_y))  # Clamp altitude

            # Horizon line in virtual pixels - moves with pitch and tilts with bank
            base_horizon = 0.35
            horizon_offset = pitch * 0.75  # Pitch affects horizon position (1.5x)
            horizon_center = vheight * (base_horizon - horizon_offset)

            # Bank tilts the horizon - calculate per-column horizon
            # Positive bank = right wing down = left side of horizon goes UP (smaller y)
            horizon_tilt = bank * vheight * 0.3
            horizon_vy_arr = np.linspace(
                horizon_center - horizon_tilt,  # Left edge (up when banking right)
                horizon_center + horizon_tilt,  # Right edge (down when banking right)
                vwidth
            ).astype(int)
            horizon_vy_arr = np.clip(horizon_vy_arr, int(vheight * 0.1), int(vheight * 0.6))

            # For sky gradient, use center horizon
            horizon_vy = int(np.clip(horizon_center, vheight * 0.15, vheight * 0.55))

            # Render to RGB buffer
            R = np.zeros((vheight, vwidth))
            G = np.zeros((vheight, vwidth))
            B = np.zeros((vheight, vwidth))
            is_terrain = np.zeros((vheight, vwidth), dtype=bool)

            # Sky gradient with tilted horizon (vectorized)
            vy_grid = np.arange(vheight)[:, np.newaxis]
            sky_mask = vy_grid < horizon_vy_arr[np.newaxis, :]
            sky_t = np.where(sky_mask, vy_grid / np.maximum(horizon_vy_arr, 1), 0)
            R[sky_mask] = (0.1 + sky_t * 0.3)[sky_mask]
            G[sky_mask] = (0.1 + sky_t * 0.4)[sky_mask]
            B[sky_mask] = (0.3 + sky_t * 0.5)[sky_mask]

            # Vectorized voxel-space terrain rendering
            y_buffer = np.full(vwidth, vheight, dtype=int)

            # Pre-compute screen X coords (reuse across frames if size unchanged)
            screen_x = (np.arange(vwidth) - vwidth / 2) / vwidth

            # Fewer samples, exponential spacing (more detail near, less far)
            distances = np.exp(np.linspace(0, np.log(400), 100))

            # Pre-allocate world_z array
            world_z_arr = np.empty(vwidth)

            for dist in distances:
                # Account for camera heading (yaw) in world coordinates
                forward_z = math.cos(cam_yaw) * dist
                forward_x = math.sin(cam_yaw) * dist
                # Perpendicular (right) vector for screen X mapping
                right_x = math.cos(cam_yaw) * dist * 2.0
                right_z = -math.sin(cam_yaw) * dist * 2.0

                world_z_arr = cam_z + forward_z + screen_x * right_z
                world_x = cam_x + forward_x + screen_x * right_x

                # Vectorized terrain height
                h = terrain_height_vec(world_x, world_z_arr, t)

                # Project to screen Y - using per-column tilted horizon
                height_on_screen = (cam_y - h) / dist * 120
                vy = np.clip((horizon_vy_arr + height_on_screen).astype(int), horizon_vy_arr, vheight - 1)

                # Find columns that need updating
                update_mask = vy < y_buffer
                if not np.any(update_mask):
                    continue

                # Get colors for all columns at once (cheaper than masking)
                r_arr, g_arr, b_arr = terrain_color_vec(h, np.full(vwidth, dist), t)

                # Grid lines
                grid_mask = (world_x.astype(int) % 25 == 0) | (int(cam_z + dist) % 25 == 0)
                r_arr[grid_mask] = np.minimum(1, r_arr[grid_mask] + 0.25)
                g_arr[grid_mask] = np.minimum(1, g_arr[grid_mask] + 0.25)
                b_arr[grid_mask] = np.minimum(1, b_arr[grid_mask] + 0.3)

                # Vertical fill using boolean indexing
                for vx in np.where(update_mask)[0]:
                    sy, ey = vy[vx], y_buffer[vx]
                    R[sy:ey, vx] = r_arr[vx]
                    G[sy:ey, vx] = g_arr[vx]
                    B[sy:ey, vx] = b_arr[vx]
                    is_terrain[sy:ey, vx] = True

                y_buffer[update_mask] = vy[update_mask]

            # Render to braille
            sys.stdout.write("\033[H")
            lines = []

            for row in range(rows):
                line_chars = []
                vy_base = row * 4

                for col in range(cols):
                    vx_base = col * 2

                    # Check if this cell is in sky (top portion, no terrain)
                    vy_end = min(vy_base + 4, vheight)
                    vx_end = min(vx_base + 2, vwidth)

                    cell_terrain = is_terrain[vy_base:vy_end, vx_base:vx_end]
                    has_terrain = np.any(cell_terrain)

                    # Sky cells - use star characters (use tilted horizon for this column)
                    col_horizon = horizon_vy_arr[vx_base]
                    if not has_terrain and vy_base < col_horizon:
                        # Calculate sky background color (same for both)
                        sky_t = (vy_base / 4) / (rows * 0.35) if rows > 0 else 0
                        sky_t = min(1, sky_t)
                        bgr = int((0.1 + sky_t * 0.3) * 255)
                        bgg = int((0.1 + sky_t * 0.4) * 255)
                        bgb = int((0.3 + sky_t * 0.5) * 255)

                        star_data = stars.get((col, row))
                        if star_data:
                            char, brightness, twinkle = star_data
                            b = brightness * (0.6 + 0.4 * math.sin(t * twinkle + col * 0.1))
                            sr = int(b * 200)
                            sg = int(b * 220)
                            sb = int(b * 255)
                            line_chars.append(f"\033[48;2;{bgr};{bgg};{bgb}m\033[38;2;{sr};{sg};{sb}m{char}")
                        else:
                            # Plain sky
                            line_chars.append(f"\033[48;2;{bgr};{bgg};{bgb}m ")
                    else:
                        # Terrain/ground cells - use braille
                        dots = np.zeros((4, 2), dtype=bool)
                        r_sum, g_sum, b_sum = 0.0, 0.0, 0.0
                        count = 0

                        for dy in range(4):
                            for dx in range(2):
                                vy = vy_base + dy
                                vx = vx_base + dx
                                if vy < vheight and vx < vwidth:
                                    brightness = 0.299 * R[vy, vx] + 0.587 * G[vy, vx] + 0.114 * B[vy, vx]
                                    if brightness > 0.2:
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
                            r_avg, g_avg, b_avg = 20, 30, 50

                        # Background blends from sky color (at horizon) to dark (deep terrain)
                        sky_t = (vy_base / 4) / (rows * 0.35) if rows > 0 else 0
                        sky_t = min(1, sky_t)
                        sky_r = 0.1 + sky_t * 0.3
                        sky_g = 0.1 + sky_t * 0.4
                        sky_b = 0.3 + sky_t * 0.5

                        # How far below horizon? (0 = at horizon, 1 = far below)
                        horizon_row = col_horizon / 4
                        depth_below = max(0, (row - horizon_row)) / (rows - horizon_row + 1)
                        depth_below = min(1, depth_below * 2)  # Faster falloff

                        # Blend sky -> dark based on depth
                        dark_r, dark_g, dark_b = 0.02, 0.04, 0.08
                        bgr = int((sky_r * (1 - depth_below) + dark_r * depth_below) * 255)
                        bgg = int((sky_g * (1 - depth_below) + dark_g * depth_below) * 255)
                        bgb = int((sky_b * (1 - depth_below) + dark_b * depth_below) * 255)
                        line_chars.append(f"\033[48;2;{bgr};{bgg};{bgb}m\033[38;2;{r_avg};{g_avg};{b_avg}m{char}")

                lines.append("".join(line_chars) + "\033[0m")

            # FPS counter
            now = time.time()
            frame_times.append(now - last_frame_time)
            last_frame_time = now
            if len(frame_times) > 30:
                frame_times.pop(0)
            fps = len(frame_times) / sum(frame_times) if frame_times else 0

            sys.stdout.write("\r\n".join(lines))
            sys.stdout.write(f"\033[1;{cols-14}H\033[48;2;0;0;0m\033[38;2;255;255;255m {fps:.1f} fps ")
            sys.stdout.flush()

            t += 0.1
            time.sleep(0.02)

    except KeyboardInterrupt:
        pass
    finally:
        print("\033[?25h\033[0m\033[2J\033[H", end="", flush=True)

if __name__ == "__main__":
    main()
