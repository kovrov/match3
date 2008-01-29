#!/usr/bin/env python

import random, math
import pygame
from pygame.locals import *

DEBUG = False


ROWS = tuple([tuple(range(i * 8,  i * 8 + 8)) for i in range(8)])
COLUMNS = tuple([tuple(range(i, 64, 8)) for i in range(8)])
STONE_SIZE = 48
CELL_SIZE = 64


# This class is the main subject of prototyping game logic.
class Board(object):
	def __init__(self):
		self.stones = []
		self.reset()

	def reset(self):
		stone_set = range(7) * 9 + [0]
		while not random.shuffle(stone_set) and self.get_matched_stones(stone_set):
			pass
		map(lambda s: s and s.kill(), self.stones)
		self.stones = [Stone(self, stone_set[i], i) for i in range(64)]
		self.selected = None
	
	def select(self, cell):
		if self.stones[cell] is None or not self.stones[cell].ready():
			return
		if self.selected is None:
			self.selected = cell
			self.stones[cell].selected = True
			return
		# just for readability
		first = self.selected
		second = cell
		# cleanup before return
		self.selected = None
		self.stones[first].selected = False
		# allow swapping only with neighboring stones
		if second not in [i for i in [first-8, first+8, first-1, first+1] if i < 64 and i > -1]:
			return
		# check if swapping valid
		tmp = list(self.stones)
		tmp[first], tmp[second] = tmp[second], tmp[first]
		if not self.get_matched_stones(tmp):
			return
		# swap
		self.stones[first], self.stones[second] = self.stones[second], self.stones[first]
		self.stones[first].cell = first
		self.stones[second].cell = second

	def get_matched_stones(self, stones):
		res = []
		for line in ROWS + COLUMNS:
			tmp = []
			last_type = None
			for n in line:
				# It is getting worse - stones[n] could be either int or object or null
				stone = stones[n]
				if stone is None or isinstance(stone, Stone) and not stone.ready():  # type is None
					if len(tmp) > 2: res += tmp
					last_type = None
					tmp = []
				else:
					if isinstance(stone, Stone):
						t = stone.type
					else:
						t = stone
					if last_type is t or last_type is None:
						tmp.append(n)
					else:
						if len(tmp) > 2: res += tmp
						tmp = [n]
					last_type = t
			if len(tmp) > 2: res += tmp
		return res

	def update(self):
		for i in self.get_matched_stones(self.stones):
			if self.stones[i] is not None:
				self.stones[i].deleted = True
		# if there are empty cells, shift stones from upper cells
		for line in COLUMNS:
			empty_cells = []  # queue
			for n in line:
				stone = self.stones[n]
				if stone is None:
					empty_cells.append(n)
				elif empty_cells:
					cell = empty_cells.pop(0)
					if stone.ready():
						stone.cell = cell
						self.stones[n] = None
						self.stones[stone.cell] = stone
						empty_cells.append(n)
					else:
						empty_cells = []
			for n in empty_cells:
				self.stones[n] = Stone(self, random.randint(0, 6), n)
		# stones must be updated in particular order
		map(lambda s: s and s.update(), self.stones)

	def release_cell(self, cell):
		self.stones[cell] = None

	def get_cell_pos(self, cell):
		col = cell % 8
		row = cell / 8
		x = col * CELL_SIZE + (CELL_SIZE - STONE_SIZE)
		y = CELL_SIZE * 8 - row * CELL_SIZE  # y is inverted in pygame
		return (x, y)

	def get_entry_pos(self, cell):
		col = cell % 8
		x = col * CELL_SIZE + (CELL_SIZE - STONE_SIZE)
		y = CELL_SIZE * 8 - 8 * CELL_SIZE
		return (x, y)



# Rest of the code is insignificant. But must work!



SCREEN_WIDTH = CELL_SIZE * 8 + (CELL_SIZE - STONE_SIZE)
SCREEN_HEIGHT = SCREEN_WIDTH
RECTS = (
	(0,   0, 48, 48), # red
	(48,  0, 48, 48), # green
	(96,  0, 48, 48), # blue
	(0,  48, 48, 48), # yellow
	(48, 48, 48, 48), # purple
	(96, 48, 48, 48), # aqua
	(0,  96, 48, 48)) # gray
BG = (24, 24, 48)
SPEED_ACC = (1.3, 1)[DEBUG] # SPEED_ACC = 1 if DEBUG else 1.3
SPEED_MIN = 2.0
SPEED_MAX = 32.0

mouse_click = None



# move this to own module
def unit_vector(src, dst, unit=1):
	"""returns "normalized vector" directed from src to dst"""
	x, y = dst[0] - src[0], dst[1] - src[1]
	#vlen = math.sqrt(x**2 + y**2)
	ang = math.atan2(y, x)
	return (math.cos(ang) * unit, math.sin(ang) * unit)


# Stone is responsible for self representation, receiving input, and resources management.
class Stone(pygame.sprite.Sprite):
	queues = tuple([[] for i in range(8)])
	images = pygame.image.load("stones.png")#.convert()
	def __init__(self, board, type, cell):
		pygame.sprite.Sprite.__init__(self, self.containers)
		# create bitmap
		self.surface = pygame.Surface((STONE_SIZE, STONE_SIZE), SRCALPHA, 32)
		self.surface.blit(self.images, (0, 0), RECTS[type])
		# pygame.sprite.Group interface
		self.image = self.surface.copy()
		self.rect = self.surface.get_rect()
		# internal state
		self.selected = False
		self.deleted = False
		self.blink = False
		self.blink_cnt = 0
		self.destruct_timer = 0
		# game-specific
		self.board = board
		self.type = type
		self.cell = cell

	def update(self):
		global mouse_click  # if ommit global, mouse_click would be CoW'ed
		# state
		if self.destruct_timer:
			self.destruct_timer -= 1
			if self.destruct_timer == 0:
				self.board.release_cell(self.cell)
				self.kill()
				return
		# presentation
		if not self.selected and mouse_click:
			if self.rect.collidepoint(mouse_click):
				self.board.select(self.cell)
				mouse_click = None
		if self.blink:
			self.blink_cnt -= 1
			if self.blink_cnt < -2:
				self.blink_cnt = 2
			if self.blink_cnt < 0:
				self.image.fill((0,0,0, 0))
			else:
				self.image.blit(self.surface, (0,0))
		# movement
		if not self.queue or self.queue and self.queue[0] is self:
			if self.move_timer > 0: self.move_timer -= 1
			if not self.move_timer and self.move_vect != (0, 0):
				if self.pos == self.target_pos: self.move_vect = (0, 0)
				else:
					if self.speed < SPEED_MAX: self.speed *= SPEED_ACC
					if self.speed > SPEED_MAX: self.speed = SPEED_MAX
					vx, vy = self.move_vect[0] * self.speed, self.move_vect[1] * self.speed
					self.pos[0] += vx
					self.pos[1] += vy
					if (vx > 0 and self.pos[0] > self.target_pos[0]) or (vx < 0 and self.pos[0] < self.target_pos[0]):
						self.pos[0] = self.target_pos[0]
						self.move_vect[0] = 0
					if (vy > 0 and self.pos[1] > self.target_pos[1]) or (vy < 0 and self.pos[1] < self.target_pos[1]):
						self.pos[1] = self.target_pos[1]
						self.move_vect[1] = 0
			if self.queue and self.pos[1] > CELL_SIZE - 1: # temp HACK!!!
				self.queue.pop(0)
				if len(self.queue) > 0:
					self.queue[0].speed = self.speed
				self.queue = None
		self.rect.left, self.rect.bottom = self.pos

	def __setattr__(self, name, value):
		if (name == "selected"):
			if (value):
				dark = self.image.copy()
				dark.fill((0,0,0, 0x7F))
				self.image.blit(dark, (0,0))
			else:
				self.image.fill((0,0,0, 0))
				self.image.blit(self.surface, (0,0))
		elif (name == "cell"):
			self.target_pos = list(self.board.get_cell_pos(value))
			self.speed = SPEED_MIN
			self.move_timer = random.randint(1, 2)
			if 'pos' not in self.__dict__:  # this is 'new' stone
				self.move_timer = random.randint(2, 3)
				self.__dict__['pos'] = list(self.board.get_entry_pos(value))
				self.queue = self.queues[value % 8]  # self.queues is static
				self.queue.append(self)
			self.move_vect = list(unit_vector(self.pos, self.target_pos))
			self.debug(value)
		elif (name == "deleted"):
			if value:
				self.destruct_timer = 30
				self.blink = True
		self.__dict__[name] = value

	def kill(self):
		if self.queue is not None:
			self.queue.remove(self)
			self.queue = None
		super(Stone, self).kill()

	def ready(self):
		if self.deleted or self.move_vect != (0,0):
			return False
		return True

	if not DEBUG:
		def debug(self, *messages): pass
	else:
		def debug(self, *messages):
			i = 0
			self.image = self.surface.copy()
			for msg in messages:
				self.image.blit(font.render(str(msg), 0, (0xFF,0xFF,0xFF)), (0,i))
				i += 8

	def __repr__(self): return "<Stone:%d:%d>" % (self.type, self.cell)

	def dump(self): print self.__dict__, "\n"


def main():
	global mouse_click, frame_time, font # if ommit global, values would be CoW'ed
	pygame.init()
	pygame.display.set_caption('swap stones to match three in a line, "r" to reset')
	window = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
	font = pygame.font.Font(pygame.font.match_font("lucidaconsole"), 8)

	# setup
	stones = pygame.sprite.Group()
	Stone.containers = stones
	board = Board()

	screen = pygame.display.get_surface()
	clock = pygame.time.Clock()
	paused = False
	while True:
		for event in pygame.event.get():
			if event.type == MOUSEBUTTONDOWN:
				if event.dict['button'] == 1:
					mouse_click = event.dict['pos']
			if event.type == KEYDOWN and event.key == K_r:
				board.reset()
			if event.type == KEYDOWN and event.key == K_d:
				map(lambda s: s.dump(), stones)
			if event.type == KEYDOWN and event.key == K_SPACE:
				paused = not paused
			if event.type == QUIT or (event.type == KEYDOWN and event.key == K_ESCAPE):
				return
		frame_time = clock.tick(30) / 1000.0
		if paused:
			continue
		board.update()
		screen.fill(BG)
		stones.draw(screen)
		pygame.display.flip()
		mouse_click = None


if __name__ == '__main__': main()
