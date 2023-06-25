# frozen_string_literal: true

# Usage: ruby app.rb train|run

args = ARGV

case args[0]
when 'train'
  puts 'Training...'
when 'run'
  puts 'Running...'
else
  puts 'Usage: ruby app.rb train|run'
end
