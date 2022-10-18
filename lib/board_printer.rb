class BoardPrinter
	attr_reader :piece_lookup


	def initialize()
		@board_size = 8
		
		@cell_height = 3
		@cell_width = 7

		@total_rows = @cell_height * @board_size + (@board_size + 1) + @cell_height
		@total_columns = @cell_width * @board_size + (@board_size + 1) + @cell_width

		@piece_lookup = {
			1 => 'W♔KNG',
			2 => 'W♕QUN',
			3 => 'W♗BSP',
			4 => 'W♘KNT',
			5 => 'W♖ROK',
			6 => 'W♙PWN',

			11 => 'B♚KNG',
			12 => 'B♛QUN',
			13 => 'B♝BSP',
			14 => 'B♞KNT',
			15 => 'B♜ROK',
			16 => 'B♟PWN',
		}
	end


	def file_index_to_letter(index)
		a_codepoint = 'a'.codepoints[0]
		letter_limits = [a_codepoint, a_codepoint + @board_size - 1]
		raise InputError.new('Invalid board index') unless (1..@board_size).cover?(index)
		return (letter_limits[0] - 1 + index).chr(Encoding::UTF_8)
	end


	def print_board_blueprint()
		@board_size.downto(1) do |rank|
			puts Array.new(@total_columns, '-').join('')
			for row in (1..@cell_height) do
				if row == (@cell_height / 2.0).ceil
					half_field = Array.new(@cell_width / 2, ' ').join('')
					print half_field + rank.to_s + half_field
				else
					print Array.new(@cell_width, ' ').join('')
				end
				puts "|" + Array.new(@board_size, Array.new(@cell_width, ' ').join('')  + "|").join('')
			end
		end
		puts Array.new(@total_columns, '-').join('')

		for row in (1..@cell_height) do
			print Array.new(@cell_width, ' ').join('')
			if row == (@cell_height / 2.0).ceil
				half_field = Array.new(@cell_width / 2, ' ').join('')
				file = 0
				puts "|" + Array.new(@board_size) { file += 1; half_field + file_index_to_letter(file).upcase + half_field + '|' }.join('')
			else
				puts "|" + Array.new(@board_size, Array.new(@cell_width, ' ').join('')  + "|").join('')
			end
		end
		print "\r"
		STDOUT.flush
	end


	def clear_printed_board(row_offset = 8)
		if row_offset + @total_rows > 0
			print "\e[#{row_offset + @total_rows}A"
		end
		print_board_blueprint()
		if row_offset > 0
			print "\e[#{row_offset}B"
		end
		print "\r"
		STDOUT.flush
	end


	def print_state_lines_blueprint()
		puts
		puts "STATUS"
		puts
		puts "TURN"
		puts "ACTION"
		puts 
		puts "RESULT"
		puts "PROMPT"
		print "\n\e[A\r"
		STDOUT.flush
	end


	def set_line_at_offset(row_offset, content, stay_at_line = false)
		print "\r"
		if row_offset > 0
			print "\e[#{row_offset}A"
		end
		print "\e[2K\r" + content
		if !stay_at_line && row_offset > 0
			print "\e[#{row_offset}B"
		end
		print "\r"
		STDOUT.flush
	end


	def set_line_status(content)
		set_line_at_offset(7, content)
	end


	def set_line_turn(content)
		set_line_at_offset(5, content)
	end


	def set_line_action(content)
		set_line_at_offset(4, content)
	end


	def set_line_result(content)
		set_line_at_offset(2, content)
	end


	def set_line_prompt(content)
		set_line_at_offset(1, content)
	end


	def file_index_to_letter(index)
		a_codepoint = 'a'.codepoints[0]
		letter_limits = [a_codepoint, a_codepoint + @board_size - 1]
		raise InputError.new('Invalid board index') unless (1..@board_size).cover?(index)
		return (letter_limits[0] - 1 + index).chr(Encoding::UTF_8)
	end


	def iterate_over_rows(row_offset = 8)
		return unless block_given?
		print "\r"
		if row_offset + @total_rows > 0
			print "\e[#{row_offset + @total_rows}A"
		end
		0.upto(@total_rows - 1) do |row|
			yield row
			print "\e[1B\r"
		end
		if row_offset > 0
			print "\e[#{row_offset}B\r"
		end
	end


	# starting from [x = 0, y = 0]
	def set_file(coord, file_data, row_offset = 8)
		coord = [coord[0], @board_size - 1 - coord[1]]
		row_col_coord = [
			coord[0] * @cell_width + coord[0] * 1 + 1 + @cell_width,
			coord[1] * @cell_height + coord[1] * 1 + 1,
		]
		subrow = 0
		iterate_over_rows(row_offset) do |row|
			next if row < row_col_coord[1] || row >= row_col_coord[1] + @cell_height
			print "\e[#{row_col_coord[0]}C"
			file_data[subrow][0...@cell_width].each_char do |char|
				if char == '#'
					print "\e[1C"
				else
					print char
				end
			end 
			subrow += 1
		end
		STDOUT.flush
	end


	# TODO: remove hardcoded '#'
	def place_pieces(board_arr, row_offset = 8)
		for rank in (0...board_arr.length) do
			for file in (0...board_arr[rank].length) do
				next if board_arr[rank][file] == 0
				unless board_arr[rank][file] > 10
					set_file([file, rank], [
						"       ",
						" #{@piece_lookup[board_arr[rank][file]]} ",
						"       "
					], row_offset)
				else
					set_file([file, rank], [
						"░░░░░░░",
						"░#{@piece_lookup[board_arr[rank][file]]}░",
						"░░░░░░░"
					], row_offset)
				end
			end
		end
		STDOUT.flush
	end

	
	# TODO: remove hardcoded length
	def show_moveable_pieces(coord_array, row_offset = 8)
		for coord in coord_array
			set_file(coord, [
				'▓▓▓▓▓▓▓',
				'▓#####▓',
				'▓▓▓▓▓▓▓',
			], row_offset)
		end
		STDOUT.flush
	end


	# TODO: remove hardcoded length
	def show_target_squares(coord_array_with_text, row_offset = 8)
		for coord_with_text in coord_array_with_text
			text = "#####"
			if coord_with_text.length >= 3
				text = coord_with_text[2]
			end
			set_file([coord_with_text[0], coord_with_text[1]], [
				'\\#####/',
				'-#####-',
				"/#{text}\\",
			], row_offset)
		end
		STDOUT.flush
	end


	# TODO: remove hardcoded '#'
	def show_forbidden_squares(coord_array_with_text, row_offset = 8)
		for coord_with_text in coord_array_with_text
			text = "×××××"
			if coord_with_text.length >= 3
				text = coord_with_text[2]
			end
			set_file([coord_with_text[0], coord_with_text[1]], [
				'×××××××',
				'×#####×',
				"×#{text}×",
			], row_offset)
		end
		STDOUT.flush
	end


	def print_action_list(action_list)
		puts "\n\n"
		action_list.each do |key, value|
			puts "#{key} \t- #{value}"
		end
		if action_list.length > 0
			print "\e[#{action_list.length + 2}A\r"
		end
	end
end