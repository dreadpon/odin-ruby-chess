
class PieceMoves
	def initialize(_board_arr = Array.new(8, Array.new(8, 0)))
		@board_arr = _board_arr
		@board_size = @board_arr.length()
		@default_checks = {
			:add_pawn_captured => true,
			:filter_king_mirror => true,
			:force_pawn_captured => false,
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


	def gen_pawn(player_range, opponent_range, coord, player_direction, special_move_log, additional_checks = {
		:add_pawn_captured => true, :force_pawn_captured => false
		})
		moves = []
		
		# add diagonal only if there's an opponent there or en passant
		# and no self pieces on immediate coord
		if additional_checks.fetch(:add_pawn_captured, true) || additional_checks.fetch(:force_pawn_captured, false)
			[-1, 1].each do |i|
				next_move = [coord[0] + i, coord[1] + player_direction]
				next if has_piece_at_coord(next_move, player_range)
				en_passant_move = [coord[0] + i, coord[1]]
				
				if has_piece_at_coord(next_move, opponent_range) || additional_checks.fetch(:force_pawn_captured, false)
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
			next_move[2] = '#LNG#' if i > 1
			unless has_piece_at_coord(next_move)
				moves.push(next_move) 
			else
				break
			end
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
		if special_move_log.any? { |e| Utility.coord_eql?(e[:coord], coord) && e[:type] == 'has_moved' && e[:state] == false }
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

				if special_move_log.any? { |e| Utility.coord_eql?(e[:coord], coord) && e[:type] == 'has_moved' && e[:state] == false }
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
			opponent_moves = gen_move_hash(opponent_range, player_range, -player_direction, special_move_log, {:filter_king_mirror => false, :force_pawn_captured => true})
			@board_arr[coord[1]][coord[0]] = self_piece
			opponent_moves.each do |key, opponent_move_arr|
				for opponent_move in opponent_move_arr
					moves.delete_if { |e| Utility.coord_eql?(e, opponent_move) }
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


	
	
	def invalidate_outside_board(moves)
		(moves.length - 1).downto(0) do |i|
			unless (0...@board_size).cover?(moves[i][0]) && (0...@board_size).cover?(moves[i][1])
				moves.delete_at(i)
			end
		end
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
		piece = Utility.get_piece_at_coord(coord, @board_arr)
		return piece == 0 || capture_range.cover?(piece)
	end


	def is_special_move_state_equal?(special_move_log, coord, type, state)
		return special_move_log.any? { |e| Utility.coord_eql?(e[:coord], coord) && e[:type] == type && e[:state] == state }
	end
end