class InputError < StandardError
   attr_reader :reason
   def initialize(reason)
      @reason = reason
   end
end


class Board
	attr_reader :board


	def initialize()
		a_codepoint = 'a'.codepoints[0]

		@board_size = 8
		@letter_limits = [a_codepoint, a_codepoint + @board_size - 1]
		@board = [
			[0, 0, 0, 0, 0, 0, 0, 0],
			[0, 6, 0, 0, 0, 0, 6, 0],
			[0, 0, 0, 1, 0, 0, 0, 0],
			[0, 0, 0, 0, 16, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0],
		]

		# @board = [
		# 	[5, 4, 3, 2, 1, 3, 4, 5],
		# 	Array.new(8, 6),
		# 	Array.new(8, 0),
		# 	Array.new(8, 0),
		# 	Array.new(8, 0),
		# 	Array.new(8, 0),
		# 	Array.new(8, 16),
		# 	[15, 14, 13, 12, 11, 13, 14, 15],
		# ]

		@cached_possible_moves = {}
	end


	def cache_possible_moves
		@cached_possible_moves[coord] = cached_possible_moves.new(target_coord, true, 'because')
	end


	def is_king_checked(source_range, opponent_range, opponent_direction)
		king = get_piece_num(source_range, 1)
		return false if king == 0
		piece_moves = PieceMoves.new()

		opponent_moves = piece_moves.gen_move_hash(@board, opponent_range, opponent_direction, source_range)
		king_coord = get_first_piece_coord(king)
		for opponent_move_arr in opponent_moves.values()
			for opponent_move in opponent_move_arr
				if opponent_move == king_coord
					return true
				end
			end
		end
	end


	def get_piece_num(source_range, piece_base_num)
		for piece in source_range
			if piece % 10 == piece_base_num
				return piece
			end
		end
		return 0
	end


	def get_all_piece_coords(piece_range)
		coords = []
		for rank in (0...@board_size) do
			for file in (0...@board_size) do
				if piece_range.cover?(@board[file][rank])
					coords << [rank, file]
				end
			end
		end
		return coords
	end


	def file_index_to_letter(index)
		raise InputError.new('Invalid board index') unless (1..@board_size).cover?(index)
		return (@letter_limits[0] - 1 + index).chr(Encoding::UTF_8)
	end

	
	def file_letter_to_index(letter)
		letter_codepoint = letter.downcase.codepoints[0]
		raise InputError.new('Invalid board letter') unless (@letter_limits[0]..@letter_limits[-1]).cover?(letter_codepoint)
		return letter_codepoint - @letter_limits[0] + 1
	end


	def is_valid_coord(string)
		begin
			string_to_coord(string)
		rescue => e
			return false
		end
		return true
	end


	def string_to_coord(string)
		file_index_to_letter(string[1].to_i)
		return [
			file_letter_to_index(string[0]) - 1,
			string[1].to_i - 1
		]
	end


	def get_first_piece_coord(piece)
		for rank in (0...@board_size) do
			for file in (0...@board_size) do
				return [rank, file] if @board[file][rank] == piece
			end
		end
	end


	def move_piece(from_coord, to_coord)
		from_piece = get_piece_at_coord(from_coord)
		to_piece = get_piece_at_coord(to_coord)
		set_piece_at_coord(to_coord, from_piece)
		set_piece_at_coord(from_coord, 0)
		return to_piece
	end


	def get_piece_at_coord(coord)
		return @board.fetch(coord[1], []).fetch(coord[0], 0)
	end


	def set_piece_at_coord(coord, piece)
		@board[coord[1]][coord[0]] = piece
	end
end


class PossibleMove
	attr_reader :coord
	attr_reader :is_allowed
	attr_reader :reason

	def initialize(_coord, _is_allowed, _reason = '')
		coord = _coord
		is_allowed = _is_allowed
		reason = _reason
	end
end


class PieceMoves
	def initialize(_board_size = 8)
		@board_size = _board_size
		@default_board = Array.new(8, Array.new(8, 0))
	end


	def gen_move_hash(board_arr, piece_range, direction, opponent_range)
		move_hash = {}
		for rank in (0...@board_size) do
			for file in (0...@board_size) do
				coord = [rank, file]
				piece = board_arr[file][rank]
				next unless piece_range.cover?(piece)
				
				moves = []
				case piece % 10
				when 6
					moves = gen_pawn(coord, direction, opponent_range, board_arr)
				when 5
					moves = gen_rook(coord, opponent_range, board_arr)
				when 4
					moves = gen_knight(coord, opponent_range, board_arr)
				when 3
					moves = gen_bishop(coord, opponent_range, board_arr)
				when 2
					moves = gen_queen(coord, opponent_range, board_arr)
				when 1
					moves = gen_king(coord, opponent_range, board_arr)
				end

				if moves.length > 0
					move_hash[coord] = moves
				end
			end
		end
		return move_hash
	end


	def invalidate_outside_board(moves)
		(moves.length - 1).downto(0) do |i|
			unless (0...@board_size).cover?(moves[i][0]) && (0...@board_size).cover?(moves[i][1])
				moves.delete_at(i)
			end
		end
	end


	def get_piece_at_coord(board_arr, coord)
		return board_arr.fetch(coord[1], []).fetch(coord[0], 0)
	end


	def has_piece_at_coord(board_arr, coord)
		return board_arr.fetch(coord[1], []).fetch(coord[0], 0) != 0
	end


	def can_move_or_capture(board_arr, coord, capture_range)
		piece = get_piece_at_coord(board_arr, coord)
		return piece == 0 || capture_range.cover?(piece)
	end


	# exclude capture, but keep it somehow to account for king checking!
	def gen_pawn(coord, direction, opponent_range, board_arr = @default_board)
		moves = [
			[coord[0] - 1, coord[1] + direction],#, 'CAPTR'],
			[coord[0] + 1, coord[1] + direction],#, 'CAPTR'],
		]

		1.upto(2) do |i|
			next_move = [coord[0], coord[1] + direction * i]
			moves.push(next_move) if can_move_or_capture(board_arr, next_move, opponent_range)
			break if has_piece_at_coord(board_arr, next_move)
		end

		invalidate_outside_board(moves)
		return moves
	end


	def gen_rook(coord, opponent_range, board_arr = @default_board)
		moves = []
		coord[0].downto(0) do |i|
			next if i == coord[0]
			next_move = [i, coord[1]]
			moves.push(next_move) if can_move_or_capture(board_arr, next_move, opponent_range)
			break if has_piece_at_coord(board_arr, next_move)
		end
		coord[0].upto(@board_size - 1) do |i|
			next if i == coord[0]
			next_move = [i, coord[1]]
			moves.push(next_move) if can_move_or_capture(board_arr, next_move, opponent_range)
			break if has_piece_at_coord(board_arr, next_move)
		end
		
		coord[1].downto(0) do |i|
			next if i == coord[1]
			next_move = [coord[0], i]
			moves.push(next_move) if can_move_or_capture(board_arr, next_move, opponent_range)
			break if has_piece_at_coord(board_arr, next_move)
		end
		coord[1].upto(@board_size - 1) do |i|
			next if i == coord[1]
			next_move = [coord[0], i]
			moves.push(next_move) if can_move_or_capture(board_arr, next_move, opponent_range)
			break if has_piece_at_coord(board_arr, next_move)
		end
		invalidate_outside_board(moves)
		return moves
	end


	def gen_knight(coord, opponent_range, board_arr = @default_board)
		moves = [
			[coord[0] - 2, coord[1] - 1],
			[coord[0] - 1, coord[1] - 2],
			[coord[0] + 2, coord[1] - 1],
			[coord[0] + 1, coord[1] - 2],
			[coord[0] - 2, coord[1] + 1],
			[coord[0] - 1, coord[1] + 2],
			[coord[0] + 2, coord[1] + 1],
			[coord[0] + 1, coord[1] + 2]
		]
		(moves.length - 1).downto(0) do |i|
			if has_piece_at_coord(board_arr, moves[i]) && !can_move_or_capture(board_arr, moves[i], opponent_range)
				moves.delete_at(i)
			end
		end
		invalidate_outside_board(moves)
		return moves
	end


	def gen_bishop(coord, opponent_range, board_arr = @default_board)
		moves = []
		deltas_index = 0
		deltas = [[-1, -1], [-1, 1], [1, -1], [1, 1]]

		while deltas_index < deltas.length do
			delta = deltas[deltas_index]
			next_move = [coord[0], coord[1]]
			i = 0
			while true do
				i += 1
				next_move = [coord[0] + delta[0] * i, coord[1] + delta[1] * i]
				break unless (0...@board_size).cover?(next_move[0]) && (0...@board_size).cover?(next_move[1])
				moves.push(next_move) if can_move_or_capture(board_arr, next_move, opponent_range)
				break if has_piece_at_coord(board_arr, next_move)
			end
			deltas_index += 1
		end
		invalidate_outside_board(moves)
		return moves
	end


	def gen_queen(coord, opponent_range, board_arr = @default_board)
		moves = gen_rook(coord, opponent_range, board_arr) + gen_bishop(coord, opponent_range, board_arr)
		return moves
	end


	def gen_king(coord, opponent_range, board_arr = @default_board)
		moves = [
			[coord[0] - 1, coord[1] - 1],
			[coord[0] - 1, coord[1]],
			[coord[0] - 1, coord[1] + 1],

			[coord[0], coord[1] - 1],
			[coord[0], coord[1] + 1],

			[coord[0] + 1, coord[1] - 1],
			[coord[0] + 1, coord[1]],
			[coord[0] + 1, coord[1] + 1],
		]
		(moves.length - 1).downto(0) do |i|
			if has_piece_at_coord(board_arr, moves[i]) && !can_move_or_capture(board_arr, moves[i], opponent_range)
				moves.delete_at(i)
			end
		end
		invalidate_outside_board(moves)
		return moves
	end
end