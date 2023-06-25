# frozen_string_literal: true

require 'chunky_png'
require 'colorize'

require_relative 'data_loader'

class NeuralNetwork

  def initialize
    @data_loader = DataLoader.new
  end

  def train
    puts '...Start training...'.blue
    @data_loader.load(kind: :training)
    generate_image_files(@data_loader.labels_with_images, count: 10)
  end

  def run
    puts 'Running...'
  end

  private

  def generate_image_files(labels_with_images, count:)
    labels_with_images.slice(0, count).each_with_index do |label_with_image, i|
      generate_png("##{i} - #{label_with_image.first}", label_with_image.last)
    end
  end

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
