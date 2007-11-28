#!/usr/bin/env python

import operator, random
import pygame
from pygame.locals import *



ROWS = [range(i * 8,  i * 8 + 8) for i in range(8)]
COLUMNS = [range(i, 64, 8) for i in range(8)]


# This class is the main subject of prototyping game logic.
class Board(object):
	initial_set = operator.repeat(range(7), 9)+[0]
	def __init__(self):
		self.stones = []
		self.reset()

	def reset(self):
		first_time = True
		while first_time or self.get_matched_stones(self.stones):
			first_time = False
			for s in self.stones:
				if s is not None: s.kill()
			random.shuffle(self.initial_set)
			self.stones = [Stone(self, self.initial_set[i], i) for i in range(64)]
		self.selected = None
	
	def select(self, pos):
		if self.stones[pos] is None or self.stones[pos].deleted:
			return
		if self.selected is None:
			self.selected = pos
			self.stones[pos].selected = True
			return
		# just for readability
		first = self.selected
		second = pos
		# cleanup before return
		self.selected = None
		self.stones[first].selected = False
		# allow swapping only with neighboring stones
		if second not in [i for i in [first-8, first+8, first-1, first+1] if i < 64 and i > -1]:
			return
		# check if swapping valid
		tmp = list(self.stones)
		tmp[first], tmp[second] = tmp[second], tmp[first]
		if not self.get_matched_stones(tmp, True):
			return
		# swap
		self.stones[first], self.stones[second] = self.stones[second], self.stones[first]
		self.stones[first].pos = first
		self.stones[second].pos = second

	def get_matched_stones(self, stones, log=False):
		res, tmp = [], []
		last_type = None
		for line in ROWS + COLUMNS:
			# I still don't like this..
			for n in line:
				if stones[n] is None or stones[n].deleted:
					if len(tmp) > 2: res += tmp
					last_type = None
					tmp = []
				else:
					if last_type is stones[n].type or last_type is None:
						tmp.append(n)
					else:
						if len(tmp) > 2: res += tmp
						tmp = [n]
					last_type = stones[n].type
			if len(tmp) > 2: res += tmp
			tmp = []
			last_type = None
		return res

	def update(self):
		for i in self.get_matched_stones(self.stones):
			if self.stones[i] is not None:
				self.stones[i].deleted = True
		# if there are empty cells, shift stones from upper cells
		for line in COLUMNS:
			empty_cells = []  # queue
			for n in reversed(line):
				stone = self.stones[n]
				if stone is None:
					empty_cells.append(n)
				elif empty_cells:
					stone.pos = empty_cells.pop(0)
					self.stones[n] = None
					self.stones[stone.pos] = stone
					empty_cells.append(n)
			for n in empty_cells:
				self.stones[n] = Stone(self, random.randint(0,6), n)

	def free_cell(self, pos):
		self.stones[pos] = None



# Rest of the code is insignificant. But must work!



STONE_SIZE = 48
CELL_SIZE = 64
SCREEN_WIDTH = CELL_SIZE * 8 + (CELL_SIZE - STONE_SIZE)
SCREEN_HEIGHT = SCREEN_WIDTH
COLORS = (
	(255, 102, 102), # red
	( 80, 224,  96), # green
	(102, 102, 230), # blue
	(255, 230, 102), # yellow
	(204, 102, 255), # purple
	(102, 232, 232), # aqua
	(160, 160, 160)) # gray
BG = (24,24,48)

mouse_click = None

# Stone is responsible for self representation, receiving input, and resources management.
class Stone(pygame.sprite.Sprite):
	def __init__(self, board, type, pos):
		pygame.sprite.Sprite.__init__(self, self.containers)
		self.surface = pygame.Surface((STONE_SIZE, STONE_SIZE))
		self.surface.fill(COLORS[type])
		# upper-left corner
		pygame.draw.rect(self.surface, BG, (0, 0, 2, 2))
		pygame.draw.rect(self.surface, BG, (0, 0, 1, 4))
		pygame.draw.rect(self.surface, BG, (0, -1, 4, 2)) # bug?
		# upper-right corner
		pygame.draw.rect(self.surface, BG, (STONE_SIZE-2, 0, 2, 2))
		pygame.draw.rect(self.surface, BG, (STONE_SIZE-1, 0, 1, 4))
		pygame.draw.rect(self.surface, BG, (STONE_SIZE-4, -1, 4, 2)) # bug!
		# lower-right corner
		pygame.draw.rect(self.surface, BG, (STONE_SIZE-2, STONE_SIZE-2, 2, 2))
		pygame.draw.rect(self.surface, BG, (STONE_SIZE-1, STONE_SIZE-4, 1, 4))
		pygame.draw.rect(self.surface, BG, (STONE_SIZE-4, STONE_SIZE-1, 4, 2)) # bug
		# lower-left corner
		pygame.draw.rect(self.surface, BG, (0, STONE_SIZE-2, 2, 2))
		pygame.draw.rect(self.surface, BG, (0, STONE_SIZE-4, 1, 4))
		pygame.draw.rect(self.surface, BG, (0, STONE_SIZE-1, 4, 2)) # bug..
		# pygame.sprite.Group interface
		self.image = self.surface.copy()
		self.rect = self.surface.get_rect()
		# game-specific
		self.board = board
		self.type = type
		self.pos = pos
		self.selected = False
		self.deleted = False
		self.blink = False
		self.blink_cnt = 0
		self.destruct_timer = 0

	def update(self):
		global mouse_click # is ommit global, mouse_click would be CoW'ed
		if self.destruct_timer:
			self.destruct_timer -= 1
			if self.destruct_timer == 0:
				self.board.free_cell(self.pos)
				self.kill()
				return
		if not self.selected and mouse_click:
			if self.rect.collidepoint(mouse_click):
				self.board.select(self.pos)
				mouse_click = None
		if self.blink:
			self.blink_cnt -= 1
			if self.blink_cnt < -2:
				self.blink_cnt = 2
			if self.blink_cnt < 0:
				self.image.set_alpha(0)
			else:
				self.image.set_alpha(255)

	def __setattr__(self, name, value):
		if (name == "selected"):
			if (value):
				self.image.set_alpha(128)
			else:
				self.image.set_alpha(255)
		elif (name == "pos"):
			row = value % 8
			col = value / 8
			self.rect.left   = row * CELL_SIZE + (CELL_SIZE - STONE_SIZE)
			self.rect.bottom = col * CELL_SIZE + CELL_SIZE - (CELL_SIZE - STONE_SIZE) / 4
		elif (name == "deleted"):
			if value:
				self.destruct_timer = 30
				self.blink = True
		self.__dict__[name] = value


def main():
	global mouse_click # is ommit global, mouse_click would be CoW'ed
	pygame.init()
	pygame.display.set_caption('swap stones to match three in a row, "r" to reset')
	window = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))

	# setup
	all = pygame.sprite.Group()
	stones = pygame.sprite.Group()
	Stone.containers = stones, all
	board = Board()

	screen = pygame.display.get_surface()
	clock = pygame.time.Clock()
	while True:
		for event in pygame.event.get():
			if event.type == MOUSEBUTTONDOWN:
				if event.dict['button'] == 1:
					mouse_click = event.dict['pos']
			if event.type == KEYDOWN and event.key == K_r:
				board.reset()
			if event.type == QUIT or (event.type == KEYDOWN and event.key == K_ESCAPE):
				return
		board.update()
		all.update()
		screen.fill(BG)
		stones.draw(screen)
		pygame.display.flip()
		clock.tick(30)
		mouse_click = None


if __name__ == '__main__': main()
