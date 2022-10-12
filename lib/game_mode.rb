require_relative 'board.rb'
require_relative 'board_printer.rb'


class GameMode
	def initialize
		@board = Board.new()
		@board_printer = BoardPrinter.new()
		@piece_moves = PieceMoves.new()
		@winner_player = 0
		@player_to_act = 1
		@turn_step = 'root'
		@turn_count = 0

		@current_moves = {}
		@chosen_piece = []

		@action_list = {
			'help' => 'returns a list of available actions',
			'move' => 'initiate piece moving sequence',
			'resign' => 'resign (concede) the game',
			'draw' => 'claim a draw if game is dragging for more than 50 turns',
			'quit' => 'quit the game',
			'save' => 'save board to file in project\'s root folder',
			'load' => 'load board from file in project\'s root folder',
			'back' => 'cancel current action',
		}

		@act_methods = {
			'help' 		=> method(:act_help),
			'quit' 		=> method(:act_quit),
			'move' 		=> method(:act_move),
			'resign' 	=> method(:act_resign),
			'draw' 		=> method(:act_draw),
			'y' 		=> method(:act_yes),
			'n' 		=> method(:act_no),
			'back' 		=> method(:act_back),
			'b' 		=> method(:act_back),
			'save' 		=> method(:act_save),
			'load' 		=> method(:act_load),
			'square'	=> method(:act_choose_square),
			'filepath'	=> method(:act_choose_filepath),
		}

		@turn_step_methods = {
			'root' 				=> method(:turn_step_root),
			'resign' 			=> method(:turn_step_resign),
			'resign_confirm' 	=> method(:turn_step_resign_confirm),
			'draw' 				=> method(:turn_step_draw),
			'draw_confirm' 		=> method(:turn_step_draw_confirm),
			'choose_piece' 		=> method(:turn_step_choose_piece),
			'choose_square' 	=> method(:turn_step_choose_square),
			'show_turn_result' 	=> method(:turn_step_show_turn_result),
			'game_over' 		=> method(:turn_step_game_over),
		}
	end


	def begin_game()
		@board_printer.print_board_blueprint 
		@board_printer.print_state_lines_blueprint
		@board_printer.set_line_status('Game has begun!')
		prepare_next_turn()

		last_command_success = true

		while @winner_player == 0 do
			render_turn_step()
			
			unless last_command_success
				set_lines({'result' => 'Invalid action!'})
			end
			last_command_success = execute_command(get_input)
			
			if @turn_step == 'show_turn_result'
				prepare_next_turn()
			end
		end

	end


	def prepare_next_turn
		@player_to_act = @player_to_act == 1 ? 2 : 1
		@turn_step = 'root'

		piece_range = (1..6)
		direction = 1
		if @player_to_act == 2
			piece_range = (11..16)
			direction = -1
		end

		if @board.is_king_checked(piece_range, (11..16), -1)
			king_coord = @board.get_first_piece_coord(1)
			opponent_moves = @piece_moves.gen_move_hash(@board.board, (11..16), -1, piece_range)
			king_moves = @piece_moves.gen_king(king_coord, (11..16), @board.board)
			
			opponent_moves.each do |key, opponent_move_arr|
				for opponent_move in opponent_move_arr
					if king_moves.include?(opponent_move)
						king_moves.delete(opponent_move)
					end
				end
			end
			@current_moves = {king_coord => king_moves}
		else
			@current_moves = @piece_moves.gen_move_hash(@board.board, piece_range, direction, (11..16))
		end
	end


	def execute_command(input)
		case input
		when 'help'
			@board_printer.print_action_list(@action_list)
			return true
		when 'quit'
			abort
		when 'move'
			@turn_step = 'choose_piece'
			return true
		when 'resign'
			@turn_step = 'resign_confirm'
			return true
		when 'draw'
			@turn_step = 'draw_confirm'
			return true
		when 'y'
			if @turn_step == 'resign_confirm'
				@turn_step = 'resign'
				return true
			elsif @turn_step == 'draw_confirm'
				@turn_step = 'draw'
				return true
			end
		when 'back', 'n', 'b'
			case @turn_step
			when 'choose_square'
				@turn_step = 'choose_piece'
				return true
			else
				@turn_step = 'root'
				return true
			end
		when ''
			if @turn_step == 'show_turn_result'
				@turn_step = 'root'
				return true
			end
		end

		if @turn_step == 'choose_piece'
			return false unless @board.is_valid_coord(input)
			return false unless @current_moves.include?(@board.string_to_coord(input))
			@turn_step = 'choose_square'
			@chosen_piece = @board.string_to_coord(input)
			return true
		elsif @turn_step == 'choose_square'
			return false unless @board.is_valid_coord(input)
			return false unless @current_moves[@chosen_piece].include?(@board.string_to_coord(input))

			@board.move_piece(@chosen_piece, @board.string_to_coord(input))

			@turn_step = 'show_turn_result'
			return true
		end
		return false
	end


	def render_turn_step(line_overrides = {})
		@board_printer.clear_printed_board()
		@board_printer.place_pieces(@board.board)

		case @turn_step
		when 'root'
			turn_text = @player_to_act == 1 ? 'WHITE turn' : 'BLACK turn'
			@board_printer.set_line_turn(turn_text)
			@board_printer.set_line_action('Waiting for action...')
			@board_printer.set_line_result('Type "help" for a list of actions')
			@board_printer.set_line_prompt('Choose an action:')
		when 'resign_confirm'
			@board_printer.set_line_action('Resigning...')
			@board_printer.set_line_result('Do you want to resign?')
			@board_printer.set_line_prompt('y/n:')
		when 'resign'
			@board_printer.set_line_action('Resigned!')
			@board_printer.set_line_result('Your opponent won')
			@board_printer.set_line_prompt('')
		when 'draw_confirm'
			@board_printer.set_line_action('Claiming a draw...')
			@board_printer.set_line_result('Do you want to claim a draw?')
			@board_printer.set_line_prompt('y/n:')
		when 'draw'
			@board_printer.set_line_action('Draw!')
			@board_printer.set_line_result('It\'s a draw!')
			@board_printer.set_line_prompt('')
		when 'choose_piece'
			@board_printer.set_line_action('Choosing a piece...')
			@board_printer.set_line_result('Use board coordinates to pick a piece')
			@board_printer.set_line_prompt('"d6" would choose 4th column, 6th row:')
			@board_printer.show_moveable_pieces(@current_moves.keys())
		when 'choose_square'
			@board_printer.set_line_action('Choosing a square...')
			@board_printer.set_line_result('Use board coordinates to move a piece')
			@board_printer.set_line_prompt('"d6" would choose 4th column, 6th row:')
			@board_printer.show_moveable_pieces([@chosen_piece])
			@board_printer.show_target_squares(@current_moves[@chosen_piece])
		when 'show_turn_result'
			@board_printer.set_line_action('')
			@board_printer.set_line_result('Moved a piece!')
			@board_printer.set_line_prompt('Press ENTER to continue')
		when 'game_over'
			nil
		end
	end
	

	def set_lines(line_overrides = {})
		line_overrides.each do |key, value|
			case key
			when 'status'
				@board_printer.set_line_status(value)
			when 'turn'
				@board_printer.set_line_turn(value)
			when 'action'
				@board_printer.set_line_action(value)
			when 'result'
				@board_printer.set_line_result(value)
			when 'prompt'
				@board_printer.set_line_prompt(value)
			end
		end
	end


	def get_input
		input = gets.chomp
		@board_printer.set_line_at_offset(1, "", true)
		return input
	end





	def test_io
		board = Board.new()
		board_printer = BoardPrinter.new()

		board_printer.print_board_blueprint 
		board_printer.print_state_lines_blueprint
		while true do
			gets
			board_printer.set_file([3, 5], [
				'row1r#wextra',
				'row2r#wextra',
				'row3r#wextra',
				'extra'
			], 9) 
			board_printer.clear_printed_board(9)
			board_printer.place_pieces([
				[5, 4, 3, 2, 1, 3, 4, 5],
				Array.new(8, 6),
				[0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0],
				Array.new(8, 16),
				[15, 14, 13, 12, 11, 13, 14, 15],
			], 9)
			board_printer.show_moveable_pieces([
				[rand(0..1), 1], [rand(2..3), 1], [rand(4..5), 1], [rand(6..7), 1]
			], 9)
			board_printer.show_target_squares([
				[0, 6], [2, 6], [4, 6], [6, 6]
			], 9)
			board_printer.show_forbidden_squares([
				[1, 6, " CHK "], [3, 6, "BLKED"], [5, 6, "BLKED"], [7, 6, "BLKED"]
			], 9)
			board_printer.set_line_status('status')
			board_printer.set_line_turn('turn')
			board_printer.set_line_action('action')
			board_printer.set_line_result('result')
			board_printer.set_line_prompt('prompt')
			board_printer.set_line_at_offset(1, "", true)
		end
	end
end