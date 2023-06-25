# frozen_string_literal: true

class ImageLoader

  attr_reader :errors, :training_images

  def initialize
    @errors = []
    @training_images = []
  end

  def load_training_images
  end
end
