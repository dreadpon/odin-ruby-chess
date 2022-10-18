require 'pry-byebug'

class InputError < StandardError
   attr_reader :reason
   def initialize(reason)
      @reason = reason
   end
end


class Board
	attr_accessor :board
	attr_accessor :special_move_log


	def initialize()
		@board_size = 8

		a_codepoint = 'a'.codepoints[0]
		@letter_limits = [a_codepoint, a_codepoint + @board_size - 1]

		@special_move_log = Array.new()
		initialize_special_move_tracking()
		
		# @board = [
		# 	# [5, 0, 0, 0, 1, 0, 0, 5],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 6, 0, 0, 0, 0],
		# 	# [0, 6, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 16, 0, 0, 0],
		# 	# [16, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# 	# [0, 0, 0, 0, 0, 0, 0, 0],
		# ]

		@board = [
			[5, 4, 3, 2, 1, 3, 4, 5],
			Array.new(8, 6),
			Array.new(8, 0),
			Array.new(8, 0),
			Array.new(8, 0),
			Array.new(8, 0),
			Array.new(8, 16),
			[15, 14, 13, 12, 11, 13, 14, 15],
		]
	end


	def only_kings_left?
		for rank in (0...@board_size) do
			for file in (0...@board_size) do
				if @board[file][rank] != 0 && @board[file][rank] % 10 != 1
					return false
				end
			end
		end
		return true
	end


	def is_king_checked(player_range, opponent_range, opponent_direction)
		king = get_piece_num(player_range, 1)
		return false if king == 0
		piece_moves = PieceMoves.new(@board)

		opponent_moves = piece_moves.gen_move_hash(opponent_range, player_range, opponent_direction, @special_move_log)
		king_coord = get_first_piece_coord(king)
		return false if king_coord.nil?

		for opponent_move_arr in opponent_moves.values()
			for opponent_move in opponent_move_arr
				if opponent_move[0] == king_coord[0] && opponent_move[1] == king_coord[1]
					return true
				end
			end
		end
		return false
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
		return nil
	end


	def initialize_special_move_tracking()
		@special_move_log = [
		{
			:coord => [0, 0],
			:type => 'has_moved',
			:state => false,
			:lifetime => -1,
		},
		{
			:coord => [7, 0],
			:type => 'has_moved',
			:state => false,
			:lifetime => -1,
		},
		{
			:coord => [4, 0],
			:type => 'has_moved',
			:state => false,
			:lifetime => -1,
		},
		{
			:coord => [0, 7],
			:type => 'has_moved',
			:state => false,
			:lifetime => -1,
		},
		{
			:coord => [7, 7],
			:type => 'has_moved',
			:state => false,
			:lifetime => -1,
		},
		{
			:coord => [4, 7],
			:type => 'has_moved',
			:state => false,
			:lifetime => -1,
		},
		]
	end


	def process_tracker_state_lifetime()
		@special_move_log.delete_if do |e|
			if e[:lifetime] > 0
				e[:lifetime] -= 1
			end
			e[:lifetime] == 0
		end
	end


	def set_tracker_state(coord, type, state)
		tracker = @special_move_log.find { |e| e[:coord][0] == coord[0] && e[:coord][1] == coord[1]}
		if tracker != nil && tracker[:type] == type
			tracker[:state] = state
		end
	end


	def set_or_add_tracker_state(coord, type, state, lifetime = -1)
		tracker = @special_move_log.find { |e| e[:coord][0] == coord[0] && e[:coord][1] == coord[1]}
		if tracker != nil && tracker[:type] == type
			tracker[:state] = state
			tracker[:lifetime] = lifetime
		else
			@special_move_log.push({
				:coord => coord,
				:type => type,
				:state => state,
				:lifetime => lifetime,
			})
		end
	end


	def take_turn(from_coord, to_coord)
		set_tracker_state(from_coord, 'has_moved', true)

		case to_coord.fetch(2, '')
		when 'CASTL'
			set_tracker_state(to_coord, 'has_moved', true)
			castle_piece(from_coord, to_coord)
		when '#LNG#'
			set_or_add_tracker_state(to_coord, :long_move, true, 2)
			move_piece(from_coord, to_coord)
		when 'PSSNT'
			en_passant_piece(from_coord, to_coord)
		when 'PROMO'
			@turn_step = 'choose_promo'
			move_piece(from_coord, to_coord)
		else
			move_piece(from_coord, to_coord)
		end
	end


	def move_piece(from_coord, to_coord)
		from_piece = get_piece_at_coord(from_coord)
		to_piece = get_piece_at_coord(to_coord)
		set_piece_at_coord(to_coord, from_piece)
		set_piece_at_coord(from_coord, 0)
		return to_piece
	end


	def castle_piece(from_coord, to_coord)
		from_piece = get_piece_at_coord(from_coord)
		to_piece = get_piece_at_coord(to_coord)

		king_coord = from_coord.clone
		king_coord[0] += from_coord[0] > to_coord[0] ? -2 : 2
		rook_coord = to_coord.clone
		rook_coord[0] = from_coord[0] > to_coord[0] ? king_coord[0] + 1 : king_coord[0] - 1

		set_piece_at_coord(king_coord, from_piece)
		set_piece_at_coord(rook_coord, to_piece)

		set_piece_at_coord(from_coord, 0)
		set_piece_at_coord(to_coord, 0)
		return to_piece
	end


	def en_passant_piece(from_coord, to_coord)
		direction = from_coord[1] < to_coord[1] ? -1 : 1
		en_passant_coord = to_coord.clone
		en_passant_coord[1] += direction

		from_piece = get_piece_at_coord(from_coord)
		to_piece = get_piece_at_coord(en_passant_coord)

		set_piece_at_coord(to_coord, from_piece)
		set_piece_at_coord(from_coord, 0)
		set_piece_at_coord(en_passant_coord, 0)
		return to_piece
	end


	def promote_piece(at_coord, to_piece)
		set_piece_at_coord(at_coord, to_piece)
		return to_piece
	end


	def get_piece_at_coord(coord)
		return @board.fetch(coord[1], []).fetch(coord[0], 0)
	end


	def set_piece_at_coord(coord, piece)
		@board[coord[1]][coord[0]] = piece
	end
end


# class PossibleMove
# 	attr_reader :coord
# 	attr_reader :is_allowed
# 	attr_reader :reason

# 	def initialize(_coord, _is_allowed, _reason = '')
# 		coord = _coord
# 		is_allowed = _is_allowed
# 		reason = _reason
# 	end
# end


class PieceMoves
	def initialize(_board_arr = Array.new(8, Array.new(8, 0)))
		@board_arr = _board_arr
		@board_size = @board_arr.length()
		@default_checks = {
			:add_pawn_captured => true,
			:filter_king_mirror => true,
		}
	end


	def gen_move_hash(player_range, opponent_range, player_direction, special_move_log, additional_checks = @default_checks)
		move_hash = {}
		for rank in (0...@board_size) do
			for file in (0...@board_size) do
				coord = [rank, file]
				piece = @board_arr[file][rank]
				next unless player_range.cover?(piece)
				
				moves = []
				case piece % 10
				when 6
					moves = gen_pawn(player_range, opponent_range, coord, player_direction, special_move_log, additional_checks)
				when 5
					moves = gen_rook(player_range, opponent_range, coord)
				when 4
					moves = gen_knight(player_range, opponent_range, coord)
				when 3
					moves = gen_bishop(player_range, opponent_range, coord)
				when 2
					moves = gen_queen(player_range, opponent_range, coord)
				when 1
					moves = gen_king(player_range, opponent_range, coord, special_move_log, player_direction, additional_checks)
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


	def get_piece_at_coord(coord)
		return @board_arr.fetch(coord[1], []).fetch(coord[0], 0)
	end


	def get_all_pieces(piece_base_code, from_range = (1..Float::INFINITY))
		pieces = []
		fitting_pieces = []
		from_range.each do |piece|
			fitting_pieces.push(piece) if piece % 10 == piece_base_code
		end

		for rank in (0...@board_size) do
			for file in (0...@board_size) do
				pieces.push([rank, file]) if fitting_pieces.include?(@board_arr[file][rank])
			end
		end
		return pieces
	end


	def get_all_rooks(from_range = (1..Float::INFINITY))
		return get_all_pieces(5, from_range)
	end


	def has_piece_at_coord(coord, from_range = (1..Float::INFINITY))
		piece = @board_arr.fetch(coord[1], []).fetch(coord[0], 0) 
		return from_range.cover?(piece)
	end


	def can_move_or_capture(coord, capture_range = (1..Float::INFINITY))
		piece = get_piece_at_coord(coord)
		return piece == 0 || capture_range.cover?(piece)
	end


	def is_special_move_state_equal?(special_move_log, coord, type, state)
		return special_move_log.any? { |e| e[:coord][0] == coord[0] && e[:coord][1] == coord[1] && e[:type] == type && e[:state] == state }
	end


	# exclude capture, but keep it somehow to account for king checking!
	def gen_pawn(player_range, opponent_range, coord, player_direction, special_move_log, additional_checks = {:add_pawn_captured => true})
		moves = []
		
		# add diagonal only if there's an opponent there or en passant
		# and no self pieces on immediate coord
		if additional_checks.fetch(:add_pawn_captured, true)
			[-1, 1].each do |i|
				next_move = [coord[0] + i, coord[1] + player_direction]
				next if has_piece_at_coord(next_move, player_range)
				en_passant_move = [coord[0] + i, coord[1]]
				
				if has_piece_at_coord(next_move, opponent_range)
					moves.push(next_move)
				elsif has_piece_at_coord(en_passant_move, opponent_range) && is_special_move_state_equal?(special_move_log, en_passant_move, :long_move, true)
					next_move[2] = 'PSSNT'
					moves.push(next_move)
				end
			end
		end
		
		# add forward only if there are no pieces there
		1.upto(2) do |i|
			next_move = [coord[0], coord[1] + player_direction * i]
			if i > 1
				next_move[2] = '#LNG#'
			end
			
			moves.push(next_move) unless has_piece_at_coord(next_move)
		end

		for move in moves
			if move[1] == 0 || move[1] == @board_size - 1
				move[2] = 'PROMO'
			end
		end

		invalidate_outside_board(moves)
		return moves
	end


	def gen_rook(player_range, opponent_range, coord)
		moves = []

		# add move if can capture an opponent
		# break if there is any piece
		coord[0].downto(0) do |i|
			next if i == coord[0]
			next_move = [i, coord[1]]
			moves.push(next_move) if can_move_or_capture(next_move, opponent_range)
			break if has_piece_at_coord(next_move)
		end
		coord[0].upto(@board_size - 1) do |i|
			next if i == coord[0]
			next_move = [i, coord[1]]
			moves.push(next_move) if can_move_or_capture(next_move, opponent_range)
			break if has_piece_at_coord(next_move)
		end
		
		coord[1].downto(0) do |i|
			next if i == coord[1]
			next_move = [coord[0], i]
			moves.push(next_move) if can_move_or_capture(next_move, opponent_range)
			break if has_piece_at_coord(next_move)
		end
		coord[1].upto(@board_size - 1) do |i|
			next if i == coord[1]
			next_move = [coord[0], i]
			moves.push(next_move) if can_move_or_capture(next_move, opponent_range)
			break if has_piece_at_coord(next_move)
		end
		invalidate_outside_board(moves)
		return moves
	end


	def gen_knight(player_range, opponent_range, coord)
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
			moves.delete_at(i) if has_piece_at_coord(moves[i], player_range)
		end
		invalidate_outside_board(moves)
		return moves
	end


	def gen_bishop(player_range, opponent_range, coord)
		moves = []
		deltas_index = 0
		deltas = [[-1, -1], [-1, 1], [1, -1], [1, 1]]

		# add while not outside board
		# can capture an opponent
		# break if there is any piece
		while deltas_index < deltas.length do
			delta = deltas[deltas_index]
			next_move = [coord[0], coord[1]]
			i = 0
			while true do
				i += 1
				next_move = [coord[0] + delta[0] * i, coord[1] + delta[1] * i]
				break unless (0...@board_size).cover?(next_move[0]) && (0...@board_size).cover?(next_move[1])
				
				moves.push(next_move) if can_move_or_capture(next_move, opponent_range)
				break if has_piece_at_coord(next_move)
			end
			deltas_index += 1
		end
		invalidate_outside_board(moves)
		return moves
	end


	def gen_queen(player_range, opponent_range, coord)
		moves = gen_rook(player_range, opponent_range, coord) + gen_bishop(player_range, opponent_range, coord)
		return moves
	end


	def gen_king(player_range, opponent_range, coord, special_move_log, player_direction = 1, additional_checks = {:filter_king_mirror => true})
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
		invalidate_outside_board(moves)

		# add castling if pieces weren't moved and have no pieces between
		castling_coords = []
		if special_move_log.any? { |e| e[:coord][0] == coord[0] && e[:coord][1] == coord[1] && e[:type] == 'has_moved' && e[:state] == false }
			for rook_coord in get_all_rooks(player_range)
				next if coord[1] != rook_coord[1]

				piece_in_range = false
				range = (rook_coord[0]...coord[0])
				if coord[0] < rook_coord[0]
					range = (coord[0]...rook_coord[0])
				end
				for file in range.to_a[1..-1]
					if has_piece_at_coord([file, coord[1]])
						piece_in_range = true
						break
					end
				end
				next if piece_in_range

				if special_move_log.any? { |e| e[:coord][0] == rook_coord[0] && e[:coord][1] == rook_coord[1] && e[:type] == 'has_moved' && e[:state] == false }
					rook_coord[2] = 'CASTL'
					castling_coords.push(rook_coord)
				end
			end
		end

		# remove if occupied by a player
		(moves.length - 1).downto(0) do |i|
			if has_piece_at_coord(moves[i], player_range)
				moves.delete_at(i)
			end
		end

		# remove if future opponent moves will result in check or king taken
		# or prevents castling
		if additional_checks.fetch(:filter_king_mirror, true)
			# this is a hack to exclude king from checks by opponent
			# so it won't block movement that would otherwise check or take him
			self_piece = @board_arr[coord[1]][coord[0]]
			@board_arr[coord[1]][coord[0]] = 0
			opponent_moves = gen_move_hash(opponent_range, player_range, -player_direction, special_move_log, {:filter_king_mirror => false})
			@board_arr[coord[1]][coord[0]] = self_piece
			
			opponent_moves.each do |key, opponent_move_arr|
				for opponent_move in opponent_move_arr
					if moves.include?(opponent_move)
						moves.delete(opponent_move)
					end
					# keep castling if king isn't blocked or in check by opponent's piece
					for rook_coord in castling_coords
						castling_coords.delete(rook_coord) unless can_castle_over_opponent_move(coord, rook_coord, opponent_move)
					end
				end
			end
		end
		moves.concat(castling_coords)
		return moves
	end


	def can_castle_over_opponent_move(king_coord, rook_coord, opponent_move_coord)
		return false if king_coord[1] != rook_coord[1]
		return true if opponent_move_coord[1] != king_coord[1]
		
		# check is inclusive to account for start and end of king positions being in check
		if king_coord[0] > rook_coord[0]
			return false if ((king_coord[0] - 2)..king_coord[0]).cover?(opponent_move_coord[0])
		else
			return false if (king_coord[0]..(king_coord[0] + 2)).cover?(opponent_move_coord[0])
		end
		return true
	end


	
end