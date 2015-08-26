require 'byebug'

class Board
  attr_accessor :board, :deck

  def initialize
    @board = Array.new(4) { Array.new(4) }
    @deck = make_deck
  end

  def populate
    i = 0
    board.each_with_index do |row, r|
      row.each_with_index do |_, c|
        board[r][c] = deck[i]
        i += 1
      end
    end
  end


  def render
    board.each do |row|
      row.each do |card|
        print card.face_up ? card.value : "X"
      end
      print "\n"
    end

    nil
  end

  def won?
    deck.all? { |card| card.face_up }
  end

  def reveal(guessed_pos)
    r, c = guessed_pos
    board[r][c].face_up = true
    system("clear")
    render
  end

  def make_deck
    deck = []

    values = (1..8).to_a
    2.times do
      values.each { |val| deck << Card.new(val) }
    end

    deck.shuffle
  end

  def hide(pos1, pos2)
    r1, c1 = pos1
    r2, c2 = pos2

    board[r1][c1].face_up = false
    board[r2][c2].face_up = false

    system("clear")
    render
  end

  def match?(pos1, pos2)
    r1, c1 = pos1
    r2, c2 = pos2

    board[r1][c1].value == board[r2][c2].value
  end
end

class Card
  attr_reader :value
  attr_accessor :face_up

  def initialize(value)
    @face_up = false
    @value = value
  end
end

class Game
  attr_accessor :current_guess, :previous_guess, :board, :player, :turns

  MAX_TURNS = 20

  def initialize(player = ComputerPlayer.new)
    @player = player
    @board = Board.new
    @current_guess = nil
    @previous_guess = nil
    @turns = 0
  end

  def play
    board.populate
    player.get_board_size(board.board.length)

    until over?
      make_guess
      self.turns += 1
    end
  end

  def over?
    turns == MAX_TURNS || board.won?
  end

  def make_guess
    self.previous_guess = player.get_move_one

    board.reveal(previous_guess)

    r, c = previous_guess
    player.receive_revealed_card(previous_guess, board.board[r][c].value)

    self.current_guess = player.get_move_two

    sleep(1)
    board.reveal(current_guess)

    r, c = current_guess
    player.receive_revealed_card(current_guess, board.board[r][c].value)


    sleep(1)
    board.hide(current_guess, previous_guess) unless board.match?(current_guess, previous_guess)

    self.previous_guess, self.current_guess = nil, nil
  end
end

class HumanPlayer
  def get_move_one
    print "Choose a card: "
    gets.gsub(/\D/,'').split(//).map(&:to_i)
  end

  def get_move_two
    print "Choose a card: "
    gets.gsub(/\D/,'').split(//).map(&:to_i)
  end

  def get_board_size(size)
  end

  def receive_revealed_card(pos, value)
  end
end

class ComputerPlayer
  attr_accessor :known_cards, :board_size, :found_match, :guessed_pos, :matched_cards

  def initialize
    @known_cards = {}
    @found_match = nil
    @guessed_pos = []
    @matched_cards = {}
  end

  def receive_revealed_card(pos, value)
    self.known_cards[pos] = value
  end

  def get_board_size(size)
    @board_size = size
  end

  def get_move_one
    self.found_match = nil

    if find_dups
      pos = find_dups
    else
      pos = select_random
    end
    self.guessed_pos << pos

    pos
  end

  def get_move_two
    if found_match
      pos = self.known_cards.select { |pos, value| value == found_match }.keys[1]
      self.matched_cards[pos] = found_match
      pos2 = self.known_cards.select { |pos, value| value == found_match }.keys[0]
      self.matched_cards[pos2] = found_match
    else
      pos = select_random
    end
    self.guessed_pos << pos

    pos
  end


  def select_random
    pos = [rand(board_size), rand(board_size)]
    while (guessed_pos.include?(pos) && guessed_pos.length < board_size ** 2) || guessed_pos[-1] == pos || matched_cards.keys.include?(pos)
      pos = [rand(board_size), rand(board_size)]
    end

    pos
  end

  def find_dups
    self.known_cards.each do |pos, value|
      if self.known_cards.values.count(value) > 1 && !matched_cards.values.include?(value)
        self.found_match = value
        return pos
      end
    end
    nil
  end
end
