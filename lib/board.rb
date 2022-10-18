require_relative 'input_error.rb'
require_relative 'piece_moves.rb'
require_relative 'shared_utility.rb'


class Board
	attr_accessor :board
	attr_accessor :special_move_log


	def initialize()
		@board_size = 8
		Utility.board_size = @board_size

		@special_move_log = Array.new()
		initialize_special_move_tracking()

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
				return false if @board[file][rank] != 0 && @board[file][rank] % 10 != 1
			end
		end
		return true
	end


	def is_king_checked(player_range, opponent_range, opponent_direction)
		king = Utility.get_piece_num(player_range, 1)
		return false if king == 0
		piece_moves = PieceMoves.new(@board)

		opponent_moves = piece_moves.gen_move_hash(opponent_range, player_range, opponent_direction, @special_move_log)
		king_coord = get_first_piece_coord(king)
		return false if king_coord.nil?

		for opponent_move_arr in opponent_moves.values()
			for opponent_move in opponent_move_arr
				return true if Utility.coord_eql?(opponent_move, king_coord)
			end
		end
		return false
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
		return Utility.get_piece_at_coord(coord, @board)
	end


	def set_piece_at_coord(coord, piece)
		@board[coord[1]][coord[0]] = piece
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
		tracker = @special_move_log.find { |e| Utility.coord_eql?(e[:coord], coord) }
		if !tracker.nil? && tracker[:type] == type
			tracker[:state] = state
		end
		return tracker
	end


	def set_or_add_tracker_state(coord, type, state, lifetime = -1)
		tracker = set_tracker_state(coord, type, state)
		if !tracker.nil?
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
end
