# frozen_string_literal: true

require 'colorize'

class DataLoader
  TRAINING_FILE = './training_data/train-images-idx3-ubyte'
  TRAINING_LABELS = './training_data/train-labels-idx1-ubyte'
  RUN_FILE = './test_data/t10k-images-idx3-ubyte'
  RUN_LABELS = './test_data/t10k-labels-idx1-ubyte'

  attr_reader :data_size

  def initialize
    @data_size = 0
  end

  def each_label_with_image(kind:, &)
    label_path = kind == :training ? TRAINING_LABELS : RUN_LABELS
    image_path = kind == :training ? TRAINING_FILE : RUN_FILE

    label_file = File.open(label_path, 'rb')
    _magic_number = label_file.read(4).unpack1('l>')
    label_count = label_file.read(4).unpack1('l>')

    image_file = File.open(image_path, 'rb')
    _magic_number = image_file.read(4).unpack1('l>')
    _image_count = image_file.read(4).unpack1('l>')
    row_count = image_file.read(4).unpack1('l>')
    col_count = image_file.read(4).unpack1('l>')

    @data_size = label_count

    label_count.times do |i|
      label = label_file.read(1).unpack1('C')
      image = read_image(image_file, row_count, col_count)
      yield(label, image, i)
    end
  ensure
    label_file.close
    image_file.close
  end

  private

  def read_image(file, row_count, col_count)
    row_count.times.map do
      col_count.times.map do
        file.read(1).unpack1('C')
      end
    end
  end
end
