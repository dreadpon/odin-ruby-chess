require_relative 'board.rb'
require_relative 'board_printer.rb'
require 'json'


class GameMode
	def initialize
		@board = Board.new()
		@turn_step = 'show_turn_result'
		@turn_count = 0

		@current_moves = {}
		@chosen_piece = []

		@winner_player = 0
		@player_to_act = 1
		@player_range = (1..6)
		@opponent_range = (11..16)
		@player_direction = 1

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
			'help' 		=> method('act_help'),
			'quit' 		=> method('act_quit'),
			'move' 		=> method('act_move'),
			'resign' 	=> method('act_resign_confirm'),
			'draw' 		=> method('act_draw_confirm'),
			'y' 		=> method('act_yes'),
			'n' 		=> method('act_no'),
			'back' 		=> method('act_back'),
			'b' 		=> method('act_back'),
			'save' 		=> method('act_save_filepath'),
			'load' 		=> method('act_load_filepath'),
			'square'	=> method('act_choose_square'),
			''			=> method('act_confirm'),
		}

		@turn_step_methods = {
			'root' 				=> method('turn_step_root'),
			'resign_confirm' 	=> method('turn_step_resign_confirm'),
			'resign' 			=> method('turn_step_resign'),
			'draw_confirm' 		=> method('turn_step_draw_confirm'),
			'draw' 				=> method('turn_step_draw'),
			'choose_piece' 		=> method('turn_step_choose_piece'),
			'choose_square' 	=> method('turn_step_choose_square'),
			'show_turn_result' 	=> method('turn_step_show_turn_result'),
			'game_over' 		=> method('turn_step_game_over'),
			'choose_promo' 		=> method('turn_step_choose_promo'),
			'save_filepath'		=> method('turn_step_filepath'),
			'load_filepath'		=> method('turn_step_filepath'),
		}
	end


	


	def begin_game()
		@board_printer = BoardPrinter.new()
		@piece_moves = PieceMoves.new(@board.board)

		@board_printer.print_board_blueprint 
		@board_printer.print_state_lines_blueprint
		@turn_step = 'show_turn_result'

		@player_to_act = opposite_player()
		
		act_confirm('')

		action_success = true

		while @winner_player == 0 do
			render_turn_step()
			action_success = execute_action(get_action)
			unless action_success
				@board_printer.set_line_result('Invalid action!')
			end
		end
		render_turn_step()
	end


	def prepare_next_turn
		@board.process_tracker_state_lifetime()
		
		@board_printer.set_line_status('')
		@player_to_act = opposite_player()
		@turn_step = 'root'

		@player_range = (1..6)
		@opponent_range = (11..16)
		@player_direction = 1

		is_checkmate = false

		if @player_to_act == 2
			@player_range = (11..16)
			@opponent_range = (1..6)
			@player_direction = -1
		end

		@current_moves = {}

		if @board.is_king_checked(@player_range, @opponent_range, -@player_direction)
			@board_printer.set_line_status('KING IN CHECK')
			player_moves = @piece_moves.gen_move_hash(@player_range, @opponent_range, @player_direction, @board.special_move_log)
			# opponent_moves = @piece_moves.gen_move_hash(@opponent_range, @player_range, -@player_direction, @board.special_move_log)
			# opponent_moves = opponent_moves.values().flatten().uniq
		
			player_moves.each do |p_coord, p_moves|
				p_moves.each do |p_move|
					test_board = Board.new()
					test_board.board = Marshal.load(Marshal.dump(@board.board))
					test_board.special_move_log = Marshal.load(Marshal.dump(@board.special_move_log))
					test_board.take_turn(p_coord, p_move)

					next if test_board.is_king_checked(@player_range, @opponent_range, -@player_direction)

					unless @current_moves.has_key?(p_coord)
						@current_moves[p_coord] = []
					end
					@current_moves[p_coord].push(p_move)
				end
			end

			if @current_moves.empty?
				is_checkmate = true
			end
		else
			@current_moves = @piece_moves.gen_move_hash(@player_range, @opponent_range, @player_direction, @board.special_move_log)
		end

		if is_checkmate
			act_game_over()
		elsif @current_moves.empty?
			act_draw()
		elsif @board.only_kings_left?
			act_draw()
		end
	end


	def opposite_player()
		return @player_to_act == 1 ? 2 : 1
	end
	




	def execute_action(action)
		return false if ['resign', 'draw', 'game_over'].include?(@turn_step)
		return method(:act_confirm).call(action) if @turn_step == 'show_turn_result'
		return @act_methods.fetch(action, method(:act_undefined)).call(action)
	end

	def act_help(action)
		return false unless @turn_step == 'root'
		@board_printer.print_action_list(@action_list)
		return true
	end

	def act_quit(action)
		return false unless @turn_step == 'root'
		abort
	end

	def act_move(action)
		return false unless @turn_step == 'root'
		@turn_step = 'choose_piece'
		return true
	end

	def act_resign_confirm(action)
		return false unless @turn_step == 'root'
		@turn_step = 'resign_confirm'
		return true
	end

	def act_draw_confirm(action)
		return false unless @turn_step == 'root'
		if @turn_count < 50
			@board_printer.set_line_result("Draw can be claimed only after 50 turns! Total turns: #{@turn_count}")
			return act_back()
		else
			@turn_step = 'draw_confirm'
		end
		return true
	end

	def act_resign(action = '')
		@turn_step = 'resign'
		@winner_player = opposite_player()
		return true
	end

	def act_draw(action = '')
		@turn_step = 'draw'
		return true
	end

	def act_game_over(action = '')
		@turn_step = 'game_over'
		@winner_player = opposite_player()
	end

	def act_yes(action)
		if @turn_step == 'resign_confirm'
			return act_resign('')
		elsif @turn_step == 'draw_confirm'
			return act_draw()
		end
		return false
	end

	def act_no(action)
		return act_back(action)
	end

	def act_back(action = '')
		if @turn_step == 'choose_square'
			@turn_step = 'choose_piece'
			return true
		elsif @turn_step != 'show_turn_result' && @turn_step != 'choose_promo'
			@turn_step = 'root'
			return true
		end
		return false
	end

	def act_confirm(action)
		case @turn_step
		when 'show_turn_result', 'root'
			@turn_step = 'root'
			prepare_next_turn()
			return true
		end
		return false
	end

	def act_save_filepath(action)
		return false unless @turn_step == 'root'
		@turn_step = 'save_filepath'
		return true
	end

	def act_load_filepath(action)
		return false unless @turn_step == 'root'
		@turn_step = 'load_filepath'
		return true
	end

	def act_undefined(action)
		if @board.is_valid_coord(action)
			if @turn_step == 'choose_piece'
				return act_choose_piece(action)
			elsif @turn_step == 'choose_square'
				return act_choose_square(action)
			end
		elsif is_path_valid(action)
			if @turn_step == 'save_filepath'
				return act_save(action)
			elsif @turn_step == 'load_filepath'
				return act_load(action)
			end
		elsif is_piece_code_valid(action, mk_promotion_array(@player_range))
			if @turn_step == 'choose_promo'
				act_promo_piece(action)
			end
		end
		return false
	end

	def act_choose_piece(action)
		action = action.downcase
		return false unless @current_moves.include?(@board.string_to_coord(action))
		@turn_step = 'choose_square'
		@chosen_piece = @board.string_to_coord(action)
		return true
	end

	def act_choose_square(action)
		action = action.downcase
		target_coord = @board.string_to_coord(action)
		return false unless @current_moves[@chosen_piece].any? { |e| e[0] == target_coord[0] && e[1] == target_coord[1]}
		@turn_step = 'show_turn_result'
		target_coord = @current_moves[@chosen_piece].find { |e| e[0] == target_coord[0] && e[1] == target_coord[1]}
		move_piece(target_coord)
		return true
	end

	def act_save(action)
		save_hash = {
			:board 				=> @board.board,
			:special_move_log 	=> @board.special_move_log,
			:player_to_act 		=> @player_to_act,
			:turn_count 		=> @turn_count,
		}
		json_string = JSON.pretty_generate(save_hash)
		File.open("save/#{action}.json","w") do |f|
			f.write(json_string)
		end
		act_back()
	end

	def act_load(action)
		json_string = File.read("save/#{action}.json")
		load_hash = JSON.parse(json_string, {:symbolize_names => true})
		@board.board 				= load_hash[:board]
		@board.special_move_log 	= load_hash[:special_move_log]
		@player_to_act 				= load_hash[:player_to_act]
		@turn_count 				= load_hash[:turn_count]
		begin_game()
	end

	def act_promo_piece(action)
		@board.promote_piece(@chosen_piece, get_piece_code(action))
		@turn_step = 'show_turn_result'
	end


	def move_piece(coord)
		@board.take_turn(@chosen_piece, coord)

		case coord.fetch(2, '')
		when 'PROMO'
			@turn_step = 'choose_promo'
			@chosen_piece = coord
		end
		@turn_count += 1
	end


	def render_turn_step()
		@board_printer.clear_printed_board()
		@board_printer.place_pieces(@board.board)
		@turn_step_methods.fetch(@turn_step, method('turn_step_undefined')).call()
	end

	def turn_step_root()
		turn_text = @player_to_act == 1 ? 'WHITE turn' : 'BLACK turn'
		@board_printer.set_line_turn(turn_text)
		@board_printer.set_line_action('Type "help" for a list of actions')
		@board_printer.set_line_prompt('Choose an action:')
	end

	def turn_step_resign_confirm()
		@board_printer.set_line_action('Resigning...')
		@board_printer.set_line_result('Do you want to resign?')
		@board_printer.set_line_prompt('y/n:')
	end

	def turn_step_draw_confirm()
		@board_printer.set_line_action('Claiming a draw...')
		@board_printer.set_line_result('Do you want to claim a draw?')
		@board_printer.set_line_prompt('y/n:')
	end

	def turn_step_resign()
		turn_text = @winner_player == 1 ? 'WHITE won' : 'BLACK won'
		@board_printer.set_line_status(turn_text)
		@board_printer.set_line_action('Resigned!')
		@board_printer.set_line_result('Your opponent won')
		@board_printer.set_line_prompt('')
	end
	
	def turn_step_draw()
		turn_text = @winner_player == 1 ? 'WHITE won' : 'BLACK won'
		@board_printer.set_line_status(turn_text)
		@board_printer.set_line_action('Draw!')
		@board_printer.set_line_result('It\'s a draw!')
		@board_printer.set_line_prompt('')
	end

	def turn_step_game_over()
		turn_text = @winner_player == 1 ? 'WHITE won' : 'BLACK won'
		@board_printer.set_line_status(turn_text)
		@board_printer.set_line_action('Checkmate!')
		@board_printer.set_line_result('You lost')
		@board_printer.set_line_prompt('')
	end


	def turn_step_filepath()
		@board_printer.set_line_action('Setting a filename...')
		@board_printer.set_line_result('Choose a filename (without an extension)')
		@board_printer.set_line_prompt('It will be saved under \'save\' folder')
	end

	def turn_step_choose_piece()
		@board_printer.set_line_action('Choosing a piece...')
		@board_printer.set_line_result('Use board coordinates to pick a piece')
		@board_printer.set_line_prompt('E.g. "d6" would choose 4th column, 6th row:')
		@board_printer.show_moveable_pieces(@current_moves.keys())
	end

	def turn_step_choose_square()
		@board_printer.set_line_action('Choosing a square...')
		@board_printer.set_line_result('Use board coordinates to move a piece')
		@board_printer.set_line_prompt('E.g. "d6" would choose 4th column, 6th row:')
		@board_printer.show_moveable_pieces([@chosen_piece])
		@board_printer.show_target_squares(@current_moves[@chosen_piece])
	end

	def turn_step_choose_promo()
		@board_printer.set_line_action('Promoting a pawn...')
		@board_printer.set_line_result('Enter a piece code to promote')
		promo_array = mk_promotion_array(@player_range)
		line = ''
		for piece_code in promo_array
			line += "#{piece_code} - #{@board_printer.piece_lookup[piece_code]}, " 
		end
		line = line[0..-3] + ':'
		@board_printer.set_line_prompt(line)
	end

	def turn_step_show_turn_result()
		@board_printer.set_line_action('')
		@board_printer.set_line_result('Moved a piece!')
		@board_printer.set_line_prompt('Press ENTER to continue')
	end

	def turn_step_undefined()
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


	def get_action
		action = gets.chomp
		@board_printer.set_line_at_offset(1, "", true)
		return action
	end


	def is_path_valid(filename)
		return filename.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_') == filename
	end


	def is_piece_code_valid(action, piece_array)
		return piece_array.include?(action.to_i)
	end


	def get_piece_code(action)
		return action.to_i
	end


	def mk_promotion_array(piece_range)
		return piece_range.select { |e| e % 10 != 1 && e % 10 != 6 }
	end

end