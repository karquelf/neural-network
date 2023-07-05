# frozen_string_literal: true

require 'singleton'

class Database
  include Singleton

  def initialize
    @db = SQLite3::Database.new 'db/neural_network.db'

    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS neural_networks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cost_average FLOAT,
        success_rate FLOAT,
        layers TEXT,
        batch_count INTEGER,
        batch_size INTEGER,
        completed_training BOOLEAN DEFAULT FALSE
      );
    SQL
  end

  def execute(sql)
    @db.execute sql
  end

  def last_insert_row_id
    @db.last_insert_row_id
  end
end
