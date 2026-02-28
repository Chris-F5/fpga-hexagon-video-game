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
yaw = math.pi * 2 * 60/360
pitch = 0
pv_inv = None
def update_matrices():
  global pv_inv
  #view_transform = np.array([[1, 0, 0],
  #                           [0, 1, 0],
  #                           [0, 0, 10]])
  #view_yaw =  np.array([[math.cos(yaw), -math.sin(yaw), 0],
  #                      [math.sin(yaw), math.cos(yaw), 0],
  #                      [0, 0, 1]])
  #view_pitch =  np.array([[1, 0, 0],
  #                        [0, math.cos(-pitch), -math.sin(-pitch)],
  #                        [0, math.sin(-pitch), math.cos(-pitch)]])
  #pv_inv = np.linalg.inv(view_pitch @ view_yaw @ view_transform)
  # ---
  #view_transform = np.array([[1, 0, 0],
  #                           [0, 1, 0],
  #                           [0, 0, 0.1]])
  #view_yaw =  np.array([[math.cos(yaw), -math.sin(yaw), 0],
  #                      [math.sin(yaw), math.cos(yaw), 0],
  #                      [0, 0, 1]])
  #view_pitch =  np.array([[1, 0, 0],
  #                        [0, math.cos(pitch), -math.sin(pitch)],
  #                        [0, math.sin(pitch), math.cos(pitch)]])
  #pv_inv = view_transform @ view_yaw @ view_pitch
  # ---
  pv_inv = np.array([[cos(yaw), -sin(yaw)*cos(pitch), sin(yaw)*sin(pitch)],
                     [sin(yaw), cos(yaw)*cos(pitch), -cos(yaw)*sin(pitch)],
                     [0, 0.1*sin(pitch), 0.1*cos(pitch)]])
update_matrices()

def color(x, y):
    #q = x * (-3 / (2 + sqrt(3))) + y * (1) + 1 * (1 / (2 + sqrt(3)))
    #r = x * (-3 / (2 + sqrt(3))) + y * (-1) + 1 * (1 / (2 + sqrt(3)))
    #s = x * (6 / (2 + sqrt(3))) + y * (0) + 1 * (sqrt(3) / (2 + sqrt(3)))

    sx = (x-size/2)/size
    sy = (y-size/2)/size
    plane_coords = pv_inv @ np.array([sx, sy, 1])
    x = plane_coords[0] / plane_coords[2]
    y = plane_coords[1] / plane_coords[2]
    if plane_coords[2] < 0:
        return np.array([0,0,0])

    #x /= 10
    #y /= 10
    q = x * (2/3)
    r = x *(-1/3) + y * (sqrt(3)/3)
    s = -q-r

    #if (q % 1) > (r % 1) and (q % 1) > (s % 1):
    #    r = math.floor(r)
    #    s = math.floor(s)
    #    q = -r-s
    #elif (r % 1) > (s % 1):
    #    q = math.floor(q)
    #    s = math.floor(s)
    #    r = -q-s
    #else:
    #    q = math.floor(q)
    #    r = math.floor(r)
    #    s = -q-r
    if abs(round(q) - q) > abs(round(r) - r) and abs(round(q) - q) > abs(round(s) - s):
        r = round(r)
        s = round(s)
        q = -r-s
    elif abs(round(r) - r) > abs(round(s) - s):
        q = round(q)
        s = round(s)
        r = -q-s
    else:
        q = round(q)
        r = round(r)
        s = -q-r


    R = 255 if q % 2 == 0 else 0
    G = 255 if r % 2 == 0 else 0
    B = 255 if s == -20 else 0
    col = np.array([R, G, B])
    return np.array(col)


def draw(screen):
    global yaw, pitch
    color_grid = np.zeros((size, size, 3), dtype=int)
    for x in range(size):
        for y in range(size):
            color_grid[x, y] = color(x, y)

    surface = pygame.surfarray.make_surface(color_grid)
    surface = pygame.transform.scale(surface, (size * scale, size * scale))
    screen.blit(surface, (0, 0))

    yaw += math.pi * 2 * 2 / 360
    pitch += math.pi * 2 * 5 / 360
    update_matrices()


while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            raise SystemExit
    draw(screen)
    pygame.display.flip()
    clock.tick(60)
