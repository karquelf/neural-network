# frozen_string_literal: true

require 'colorize'

class DataLoader

  attr_reader :errors, :labels_with_images

  TRAINING_FILE = './training_data/train-images-idx3-ubyte'
  TRAINING_LABELS = './training_data/train-labels-idx1-ubyte'
  RUN_FILE = './test_data/t10k-images-idx3-ubyte'
  RUN_LABELS = './test_data/t10k-labels-idx1-ubyte'

  def initialize
    @errors = []
    @labels_with_images = []
  end

  def load(kind:)
    case kind
    when :training
      load_labels(path: TRAINING_LABELS)
      load_images(path: TRAINING_FILE)
    when :run
      load_labels(path: RUN_LABELS)
      load_images(path: RUN_FILE)
    else
      raise 'Unknown kind of data'
    end
  end

  private

  def load_labels(path:)
    puts "Loading labels from #{path}...".light_green
    File.open(path, 'rb') do |file|
      magic_number = file.read(4).unpack1('l>')
      label_count = file.read(4).unpack1('l>')
      puts "Magic number: #{magic_number}"
      puts "Label count: #{label_count}"
      label_count.times do |i|
        print "\r#{i + 1} / #{label_count} labels".light_green
        label = file.read(1).unpack1('C')
        @labels_with_images << [label]
      end
      puts "\n"
    end
  end

  def load_images(path:)
    puts "Loading images from #{path}...".light_magenta
    File.open(path, 'rb') do |file|
      magic_number = file.read(4).unpack1('l>')
      image_count = file.read(4).unpack1('l>')
      row_count = file.read(4).unpack1('l>')
      col_count = file.read(4).unpack1('l>')
      puts "Magic number: #{magic_number}"
      puts "Image count: #{image_count}"
      puts "Row count: #{row_count}"
      puts "Col count: #{col_count}"
      image_count.times do |i|
        print "\r#{i + 1} / #{image_count} images".light_magenta
        @labels_with_images[i] << read_image(file, row_count, col_count)
      end
      puts "\n"
    end
  end

  def read_image(file, row_count, col_count)
    row_count.times.map do
      col_count.times.map do
        file.read(1).unpack1('C')
      end
    end
  end
end
