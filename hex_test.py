import math
import pygame
import numpy as np
from math import sqrt
from math import sin
from math import cos

pygame.init()
screen = pygame.display.set_mode((500, 500))
pygame.display.set_caption("Pattern")
clock = pygame.time.Clock()

scale = 2
size = 200

a = 1
fov = 90
near = 1
far = 10
yaw = math.pi * 2 * 60 / 360
pitch = math.pi * 2 * 60 / 360
pv_inv = np.eye(3)


def update_matrices():
    global pv_inv
    #view_yaw = np.array(
    #    [
    #        [math.cos(yaw), -math.sin(yaw), 0],
    #        [math.sin(yaw), math.cos(yaw), 0],
    #        [0, 0, 1],
    #    ]
    #)
    #view_pivot_pre = np.array([[1, 0, 0], [0, 1, 50], [0, 0, 1]])
    #view_pivot_post = np.array([[1, 0, 0], [0, 1, -50], [0, 0, 1]])
    #view_transform = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 20]])
    #view_pitch = np.array(
    #    [
    #        [1, 0, 0],
    #        [0, math.cos(-pitch), -math.sin(-pitch)],
    #        [0, math.sin(-pitch), math.cos(-pitch)],
    #    ]
    #)
    #pv_inv = np.linalg.inv(
    #    view_pitch @ view_transform @ view_pivot_post @ view_yaw @ view_pivot_pre
    #)
    # ---
    #view_transform = np.array([[1, 0, 0],
    #                           [0, 1, 0],
    #                           [0, 0, 0.1]])
    #view_yaw =  np.array([[math.cos(yaw), -math.sin(yaw), 0],
    #                      [math.sin(yaw), math.cos(yaw), 0],
    #                      [0, 0, 1]])
    #view_pivot_pre = np.array([[1, 0, 0], [0, 1, -50], [0, 0, 1]])
    #view_pivot_post = np.array([[1, 0, 0], [0, 1, 50], [0, 0, 1]])
    #view_pitch =  np.array([[1, 0, 0],
    #                       [0, math.cos(pitch), -math.sin(pitch)],
    #                       [0, math.sin(pitch), math.cos(pitch)]])
    #pv_inv = view_pivot_pre @ view_yaw @ view_pivot_post @ view_transform @ view_pitch
    # ---
    h = 8
    d = 50
    pv_inv = np.array([[cos(yaw), -sin(yaw)*cos(pitch)-sin(yaw)*sin(pitch)*(1/h)*d, sin(yaw)*sin(pitch)-sin(yaw)*cos(pitch)*(1/h)*d],
                       [sin(yaw), cos(yaw)*cos(pitch)+cos(yaw)*sin(pitch)*(1/h)*d-sin(pitch)*(1/h)*d, -cos(yaw)*sin(pitch)+cos(yaw)*cos(pitch)*(d/h)-cos(pitch)*(d/h)],
                       [0, (1/h)*sin(pitch), (1/h)*cos(pitch)]])


update_matrices()


def draw(screen):
    global yaw, pitch

    X, Y = np.meshgrid(np.arange(size), np.arange(size), indexing="ij")
    SX = (X - size / 2) / size
    SY = (Y - size / 2) / size

    coords = np.stack([SX, SY, np.ones_like(SX)], axis=-1)
    plane_coords = coords @ pv_inv.T

    pc0 = plane_coords[..., 0]
    pc1 = plane_coords[..., 1]
    pc2 = plane_coords[..., 2]

    bits = 16
    b = np.round(pc2 * (2**bits)) / (2**bits)

    with np.errstate(divide="ignore", invalid="ignore"):
        x = pc0 / b
        y = pc1 / b

    valid_mask = pc2 >= 0

    q = x * (2 / 3)
    r = x * (-1 / 3) + y * (np.sqrt(3) / 3)
    s = -q - r

    q_round = np.round(q)
    r_round = np.round(r)
    s_round = np.round(s)

    q_diff = np.abs(q_round - q)
    r_diff = np.abs(r_round - r)
    s_diff = np.abs(s_round - s)

    cond_q = (q_diff > r_diff) & (q_diff > s_diff)
    cond_r = ~cond_q & (r_diff > s_diff)
    cond_s = ~cond_q & ~cond_r

    q_final = np.where(cond_q, -r_round - s_round, q_round)
    r_final = np.where(cond_r, -q_round - s_round, r_round)
    s_final = np.where(cond_s, -q_round - r_round, s_round)

    R = np.where(q_final % 2 == 0, 255, 0)
    G = np.where(r_final % 2 == 0, 255, 0)
    B = np.where(s_final % 20 == 10, 255, 0)

    color_grid = np.stack([R, G, B], axis=-1).astype(int)
    color_grid[~valid_mask] = 0

    surface = pygame.surfarray.make_surface(color_grid)
    surface = pygame.transform.scale(surface, (size * scale, size * scale))
    screen.blit(surface, (0, 0))

    yaw -= math.pi * 2 * 1 / 360
    pitch = math.pi * 2 * 60 / 360
    update_matrices()


while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            raise SystemExit
    draw(screen)
    pygame.display.flip()
    clock.tick(60)
