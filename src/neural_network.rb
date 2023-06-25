# frozen_string_literal: true

require 'benchmark'
require 'chunky_png'
require 'colorize'

require_relative 'data_loader'

class NeuralNetwork

  def initialize
    @data_loader = DataLoader.new
  end

  def train
    puts '...Start training...'.blue
    time = Benchmark.measure do
      @data_loader.each_label_with_image(kind: :training) do |label, image, i|
        print "\r#{i + 1} / #{@data_loader.data_size} images".light_magenta
      end
    end
    puts "\n...Training finished in #{time.real.round(2)} seconds...".blue
  end

  def run
    puts 'Running...'
  end

  private

  def generate_png(label, image)
    png = ChunkyPNG::Image.new(image.first.size, image.size, ChunkyPNG::Color::TRANSPARENT)
    image.each_with_index do |row, y|
      row.each_with_index do |pixel, x|
        png[x, y] = ChunkyPNG::Color.rgb(pixel, pixel, pixel)
      end
    end
    png.save("tmp/#{label}.png", interlace: true)
  end

end
