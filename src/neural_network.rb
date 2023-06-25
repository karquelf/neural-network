# frozen_string_literal: true

require 'colorize'

require_relative 'data_loader'

class NeuralNetwork

  def initialize
    @data_loader = DataLoader.new
  end

  def train
    puts '...Start training...'.blue
    log_step('Loading data...') { @data_loader.load(kind: :training) }
    puts @data_loader.training_images_with_labels.size
  end

  def run
    puts 'Running...'
  end

  private

  def log_step(message, &)
    print message
    yield
    puts ' ok'.green
  rescue StandardError => e
    puts ' ko'.red
    raise e
  end

end
