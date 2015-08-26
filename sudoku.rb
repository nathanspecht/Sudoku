require 'colorize'

class Board
  attr_accessor :grid

  def initialize(grid = [])
    @grid = grid
  end

  def [](row, col)
    @grid[row][col]
  end

  def []=(row, col, mark)
    @grid[row][col] = mark
  end

  def from_file(filename)
    File.open(filename).each_line do |line|
      row = []
      line.chomp.split(//).each do |val|
        row << Tile.new(val)
      end
      @grid << row
    end
  end

  def update(value, pos)
    unless self.[](*pos).given
      self.[](*pos).value = value
    end
  end

  def display
    print "-------------------------\n"
    grid.each_with_index do |row, r|
      print "| "
      row.each_with_index do |tile, c|
        print tile.given ? tile.value.cyan : tile.value
        print (c + 1) % 3 == 0 ? " | " : " "
      end
      print "\n"
      print "-------------------------\n" if (r + 1) % 3 == 0
    end

    nil
  end

  def solved?
    check_rows && check_columns && check_squares
  end

  def check_rows
    grid.each do |row|
      return false if row.uniq != row
    end

    true
  end

  def check_columns
    grid.transpose.each do |col|
      return false if col.uniq != col
    end

    true
  end

  def check_squares
    squares = make_squares
    squares.each do |square|
      return false if square.uniq != square
    end

    true
  end

  def make_squares
    squares = [[[], [], []], [[], [], []], [[], [], []]]
    i, j = 0, 0

    grid.each_with_index do |row, r|
      row.each_with_index do |tile, c|
        squares[i][j] << tile.value
        j += 1 if (c + 1) % 3 == 0
      end
      j = 0
      i += 1 if (r + 1) % 3 == 0
    end

    squares.flatten(1)
  end

end

class Tile
  attr_accessor :value
  attr_reader :given

  def initialize(value)
    @given = value.to_i.zero? ? false : true
    @value = value
  end
end

class Game
  attr_accessor :board

  def initialize(board = Board.new)
    @board = board
  end

  def play
    until board.solved?
      value, pos = get_input
      board.update(value, pos)
      board.display
    end
  end

  def get_input
    print "Enter coordinates: "
    pos = gets.gsub(/\D/,'').split(//).map(&:to_i)

    while board[*pos].given
      puts "Cannot change given value."
      print "Enter coordinates: "
      pos = gets.gsub(/\D/,'').split(//).map(&:to_i)
    end

    print "Enter value: "
    value = gets.chomp

    [value, pos]
  end

end

if __FILE__ == $PROGRAM_NAME
  board = Board.new
  board.from_file("./Puzzles/sudoku1.txt")
  game = Game.new(board)
  game.play
end
