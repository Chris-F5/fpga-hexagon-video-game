import math
import pygame
import numpy as np
from math import sqrt, sin, cos

pygame.init()
screen = pygame.display.set_mode((500, 500))
pygame.display.set_caption("Pattern")
clock = pygame.time.Clock()

scale = 2
size = 200

yaw = 0
pitch = 0
pv_inv = None


sin_table = np.array(
    [int(math.sin(2.0 * 3.14159265 * i / 256.0) * 127.0) for i in range(256)],
    dtype=np.int8,
)

def sin8(theta):
    return sin_table[theta%256].astype(np.int32)
def cos8(theta):
    return sin_table[(theta+64)%256].astype(np.int32)

def sini(theta):
    #return sin(theta*2*math.pi/258)
    return sin_table[theta]/128
def cosi(theta):
    #return cos(theta*2*math.pi/258)
    return sin_table[(theta+64)%256]/128


def update_matrices():
    global pv_inv
    inv_h = 16
    d = 10
    pv_inv = np.array(
        [
            [127 * cos8(yaw), -sin8(yaw) * cos8(pitch) -sin8(yaw)*sin8(pitch)*inv_h*d, sin8(yaw) * sin8(pitch) + -sin(yaw)*cos(pitch)*inv_h*d],
            [127 * sin8(yaw), cos8(yaw) * cos8(pitch) + cos8(yaw)*sin8(pitch)*inv_h*d - sin8(pitch)*inv_h*d, -cos8(yaw) * sin8(pitch) + cos8(yaw)*cos8(pitch)*inv_h*d - cos8(pitch)*inv_h*d],
            [0, inv_h * sin8(pitch), inv_h * cos8(pitch)],
        ], dtype=np.int32
    )
    #pv_inv = np.array(
    #    [
    #        [cos8(yaw)*128, -sin8(yaw) * cos8(pitch), sin8(yaw) * sin8(pitch)],
    #        [sin8(yaw)*128, cos8(yaw) * cos8(pitch), -cos8(yaw) * sin8(pitch)],
    #        [0, inv_h * sin8(pitch), inv_h * cos8(pitch)],
    #    ]#, dtype=np.int32
    #)/(128**2)
    #pv_inv = np.array(
    #    [
    #        [cosi(yaw), -sini(yaw) * cosi(pitch), sini(yaw) * sini(pitch)],
    #        [sini(yaw), cosi(yaw) * cosi(pitch), -cosi(yaw) * sini(pitch)],
    #        [0, (1/inv_h) * sini(pitch), (1/inv_h) * cosi(pitch)],
    #    ]#, dtype=np.int32
    #)


update_matrices()

X, Y = np.meshgrid(np.arange(size), np.arange(size), indexing="ij")
#sx = (X - size // 2) / size
#sy = (Y - size // 2) / size
sx = X.astype(np.int64) - (size//2)
sy = Y.astype(np.int64) - (size//2)
coords = np.stack([sx, sy, np.full_like(sx, size)], axis=-1)


def draw(screen):
    global yaw, pitch

    print(np.max(pv_inv), np.max(coords))
    plane_coords = np.dot(coords, pv_inv.T).astype(np.int32)
    plane_x = plane_coords[..., 0]
    plane_y = plane_coords[..., 1]
    plane_z = plane_coords[..., 2]

    with np.errstate(divide="ignore", invalid="ignore"):
        x_val = plane_x * 10 // plane_z
        y_val = plane_y * 10 // plane_z
    x_val = x_val.astype(float) / 10
    y_val = y_val.astype(float) / 10

    mask = (plane_z < 0)

    q = x_val * (2 / 3)
    r = x_val * (-1 / 3) + y_val * (sqrt(3) / 3)
    s = -q - r

    q_round = np.round(q)
    r_round = np.round(r)
    s_round = np.round(s)

    q_diff = np.abs(q_round - q)
    r_diff = np.abs(r_round - r)
    s_diff = np.abs(s_round - s)

    cond1 = (q_diff > r_diff) & (q_diff > s_diff)
    cond2 = (~cond1) & (r_diff > s_diff)
    cond3 = ~(cond1 | cond2)

    q_final = np.zeros_like(q)
    r_final = np.zeros_like(r)
    s_final = np.zeros_like(s)

    q_final[cond1] = -r_round[cond1] - s_round[cond1]
    r_final[cond1] = r_round[cond1]
    s_final[cond1] = s_round[cond1]

    q_final[cond2] = q_round[cond2]
    r_final[cond2] = -q_round[cond2] - s_round[cond2]
    s_final[cond2] = s_round[cond2]

    q_final[cond3] = q_round[cond3]
    r_final[cond3] = r_round[cond3]
    s_final[cond3] = -q_round[cond3] - r_round[cond3]

    R = np.where(q_final % 2 == 0, 255, 0)
    G = np.where(r_final % 2 == 0, 255, 0)
    B = np.where(s_final == -20, 255, 0)

    color_grid = np.stack([R, G, B], axis=-1)
    color_grid[mask] = [0, 0, 0]

    surface = pygame.surfarray.make_surface(color_grid.astype(np.uint8))
    surface = pygame.transform.scale(surface, (size * scale, size * scale))
    screen.blit(surface, (0, 0))

    #yaw += math.pi * 2 * 1/360
    #pitch = math.pi * 2 * 30 / 128
    yaw += 1
    pitch = 50
    update_matrices()


while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            raise SystemExit
    draw(screen)
    pygame.display.flip()
    clock.tick(60)
