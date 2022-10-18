class Utility
	

	@@board_size = 8
	@@a_codepoint = 'a'.codepoints[0]
	@@letter_limits = [@@a_codepoint, @@a_codepoint + @@board_size - 1]
	

	def self.board_size=(val)
		@@board_size = val
	end

	
	def self.file_index_to_letter(index)
		raise InputError.new('Invalid board index') unless (1..@@board_size).cover?(index)
		return (@@letter_limits[0] - 1 + index).chr(Encoding::UTF_8)
	end

	
	def self.file_letter_to_index(letter)
		letter_codepoint = letter.downcase.codepoints[0]
		raise InputError.new('Invalid board letter') unless (@@letter_limits[0]..@@letter_limits[-1]).cover?(letter_codepoint)
		return letter_codepoint - @@letter_limits[0] + 1
	end


	def self.is_valid_coord(string)
		begin
			string_to_coord(string)
		rescue => e
			return false
		end
		return true
	end


	def self.string_to_coord(string)
		self.file_index_to_letter(string[1].to_i)
		return [
			self.file_letter_to_index(string[0]) - 1,
			string[1].to_i - 1
		]
	end


	def self.get_piece_num(source_range, piece_base_num)
		for piece in source_range
			if piece % 10 == piece_base_num
				return piece
			end
		end
		return 0
	end


	def self.coord_eql?(coord_1, coord_2)
		return coord_1[0] == coord_2[0] && coord_1[1] == coord_2[1]
	end


	def self.get_piece_at_coord(coord, board_arr)
		return board_arr.fetch(coord[1], []).fetch(coord[0], 0)
	end


	def self.is_path_valid(filename)
		return filename.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_') == filename
	end


	def self.is_piece_code_valid(action, piece_array)
		return piece_array.include?(action.to_i)
	end


	def self.get_piece_code(action)
		return action.to_i
	end


	def self.mk_promotion_array(piece_range)
		return piece_range.select { |e| e % 10 != 1 && e % 10 != 6 }
	end
end