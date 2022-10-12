require_relative '../lib/board.rb'


describe Board do
	describe "#file_index_to_letter" do
		it "returns index converted to board letter" do
			expect(subject.file_index_to_letter(5)).to eql('e')
		end
		it "throws error when index is smaller than 0" do
			expect { subject.file_index_to_letter(-1) }.to raise_error(InputError)
		end
		it "throws error when index is bigger than board size (default: 8)" do
			expect { subject.file_index_to_letter(9) }.to raise_error(InputError)
		end
	end

	describe "#file_letter_to_index" do
		it "returns letter converted to board index" do
			expect(subject.file_letter_to_index('e')).to eql(5)
		end
		it "throws error when letter is before letter 'a'" do
			expect { subject.file_letter_to_index('`') }.to raise_error(InputError)
		end
		it "throws error when letter is after last board letter (default: 'h')" do
			expect { subject.file_letter_to_index('i') }.to raise_error(InputError)
		end
	end
end


describe PieceMoves do
	describe "#gen_pawn" do
		it "returns moves for a pawn" do
			expect(subject.gen_pawn([4, 4])).to contain_exactly(
				[4, 5], [4, 6], [3, 5, 'capture'], [5, 5, 'capture'],
			)
		end
		it "removes moves outside the board" do
			expect(subject.gen_pawn([0, 6])).to contain_exactly(
				[0, 7], [1, 7, 'capture'],
			)
		end
		it "removes moves blocked by other pieces" do
			board_arr = Array.new(8) { Array.new(8, 0) }
			board_arr[4][5] = 1
			expect(subject.gen_pawn([4, 4], 1, board_arr)).to contain_exactly(
				[3, 5, 'capture'], [5, 5, 'capture'],
			)
		end
		it "moves for a pawn support different direction" do
			expect(subject.gen_pawn([4, 4], -1)).to contain_exactly(
				[4, 3], [4, 2], [3, 3, 'capture'], [5, 3, 'capture'],
			)
		end
		it "removes moves outside board when moving in a different direction" do
			expect(subject.gen_pawn([0, 1], -1)).to contain_exactly(
				[0, 0], [1, 0, 'capture'],
			)
		end
		it "removes moves blocked by other pieces in a different direction" do
			board_arr = Array.new(8) { Array.new(8, 0) }
			board_arr[4][3] = 1
			expect(subject.gen_pawn([4, 4], -1, board_arr)).to contain_exactly(
				[3, 3, 'capture'], [5, 3, 'capture'],
			)
		end
	end

	describe "#gen_rook" do
		it "returns moves for a rook" do
			expect(subject.gen_rook([4, 4])).to contain_exactly(
				[0, 4], [1, 4], [2, 4], [3, 4], [5, 4], [6, 4], [7, 4], 
				[4, 0], [4, 1], [4, 2], [4, 3], [4, 5], [4, 6], [4, 7],
			)
		end
		it "removes moves outside the board" do
			expect(subject.gen_rook([1, 6])).to contain_exactly(
				[0, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6], [7, 6],
				[1, 0], [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 7],
			)
		end
		it "removes moves blocked by other pieces" do
			board_arr = Array.new(8) { Array.new(8, 0) }
			board_arr[4][3] = 1
			board_arr[6][4] = 1
			expect(subject.gen_rook([4, 4], board_arr)).to contain_exactly(
				[0, 4], [1, 4], [2, 4], [3, 4], [5, 4], 
				[4, 5], [4, 6], [4, 7],
			)
		end
	end

	describe "#gen_knight" do
		it "returns moves for a knight" do
			expect(subject.gen_knight([4, 4])).to contain_exactly(
				[2, 5], [3, 6], [5, 6], [6, 5], [2, 3], [3, 2], [5, 2], [6, 3],
			)
		end
		it "removes moves outside the board" do
			expect(subject.gen_knight([1, 6])).to contain_exactly(
				[0, 4], [2, 4], [3, 5], [3, 7],
			)
		end
		it "removes moves blocked by other pieces, but allows jumping over" do
			board_arr = Array.new(8) { Array.new(8, 0) }
			board_arr[3][2] = 1
			board_arr[6][3] = 1
			board_arr[3][5] = 1
			board_arr[4][2] = 1
			expect(subject.gen_knight([4, 4], board_arr)).to contain_exactly(
				[2, 5], [3, 6], [5, 6], [6, 5], [2, 3], [5, 2],
			)
		end
	end

	describe "#gen_bishop" do
		it "returns moves for a bishop" do
			expect(subject.gen_bishop([4, 4])).to contain_exactly(
				[0, 0], [1, 1], [2, 2], [3, 3], [5, 5], [6, 6], [7, 7], 
				[1, 7], [2, 6], [3, 5], [5, 3], [6, 2], [7, 1],
			)
		end
		it "removes moves outside the board" do
			expect(subject.gen_bishop([1, 6])).to contain_exactly(
				[0, 7], [2, 7], [0, 5], [2, 5], [3, 4], [4, 3], [5, 2], [6, 1], [7, 0],
			)
		end
		it "removes moves blocked by other pieces" do
			board_arr = Array.new(8) { Array.new(8, 0) }
			board_arr[5][5] = 1
			board_arr[6][2] = 1
			expect(subject.gen_bishop([4, 4], board_arr)).to contain_exactly(
				[0, 0], [1, 1], [2, 2], [3, 3],
				[1, 7], [2, 6], [3, 5], [5, 3],
			)
		end
	end

	describe "#gen_queen" do
		it "returns moves for a queen" do
			expect(subject.gen_queen([4, 4])).to contain_exactly(
				[0, 4], [1, 4], [2, 4], [3, 4], [5, 4], [6, 4], [7, 4], 
				[4, 0], [4, 1], [4, 2], [4, 3], [4, 5], [4, 6], [4, 7],
				[0, 0], [1, 1], [2, 2], [3, 3], [5, 5], [6, 6], [7, 7], 
				[1, 7], [2, 6], [3, 5], [5, 3], [6, 2], [7, 1],
			)
		end
		it "removes moves outside the board" do
			expect(subject.gen_queen([1, 6])).to contain_exactly(
				[0, 6], [2, 6], [3, 6], [4, 6], [5, 6], [6, 6], [7, 6],
				[1, 0], [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 7],
				[0, 7], [2, 7], [0, 5], [2, 5], [3, 4], [4, 3], [5, 2], [6, 1], [7, 0],
			)
		end
		it "removes moves blocked by other pieces" do
			board_arr = Array.new(8) { Array.new(8, 0) }
			board_arr[4][3] = 1
			board_arr[6][4] = 1
			board_arr[5][5] = 1
			board_arr[6][2] = 1
			expect(subject.gen_queen([4, 4], board_arr)).to contain_exactly(
				[0, 4], [1, 4], [2, 4], [3, 4], [5, 4], 
				[4, 5], [4, 6], [4, 7],
				[0, 0], [1, 1], [2, 2], [3, 3],
				[1, 7], [2, 6], [3, 5], [5, 3],
			)
		end
	end

	describe "#gen_king" do
		it "returns moves for a king" do
			expect(subject.gen_king([4, 4])).to contain_exactly(
				[3, 5], [4, 5], [5, 5], [3, 4], [5, 4], [3, 3], [4, 3], [5, 3],
			)
		end
		it "removes moves outside the board" do
			expect(subject.gen_king([0, 6])).to contain_exactly(
				[0, 7], [1, 7], [1, 6], [0, 5], [1, 5]
			)
		end
		it "removes moves blocked by other pieces" do
			board_arr = Array.new(8) { Array.new(8, 0) }
			board_arr[3][3] = 1
			board_arr[5][4] = 1
			expect(subject.gen_king([4, 4], board_arr)).to contain_exactly(
				[3, 5], [4, 5], [5, 5], [3, 4], [4, 3], [5, 3],
			)
		end
	end
end