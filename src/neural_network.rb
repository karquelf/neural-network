# frozen_string_literal: true

require 'colorize'

require_relative 'image_loader'

class NeuralNetwork

  def initialize
    @image_loader = ImageLoader.new
  end

  def train
    puts '...Start training...'.blue
    log_step('Loading training images...') { @image_loader.load_training_images }
    puts @image_loader.training_images.size
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
