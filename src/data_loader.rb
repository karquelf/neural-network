# frozen_string_literal: true

class DataLoader

  attr_reader :errors, :training_images_with_labels

  TRAINING_FILE = 'training_data/train-images-idx3-ubyte'
  TRAINING_LABELS = 'training_data/train-labels-idx1-ubyte'
  TEST_FILE = 'test_data/t10k-images-idx3-ubyte'
  TEST_LABELS = 'test_data/t10k-labels-idx1-ubyte'

  def initialize
    @errors = []
    @training_images_with_labels = []
  end

  def load(kind:)
  end
end
