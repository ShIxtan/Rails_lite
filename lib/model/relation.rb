require_relative 'db_connection'
require_relative 'associatable'
require 'active_support/inflector'

class Relation

  attr_accessor :model

  def initialize(model = Object)
    @model = model
    @query_options = {}
  end

  [:from, :joins, :select, :where].each do |name|
    define_method("#{name}_options") do
      @query_options[name] ||= {}
    end
  end

  def select_string
    select_options.keys.join(", ")
  end

  def from_string
    from_options.keys.join(", ")
  end

  def where(params)
    select_options["*"] = true
    where_options.merge!(params) unless params.nil?
    self
  end

  def where_string
    where_options.map do |column, value|
      "#{column} = '#{value}'"
    end.join(" AND ")
  end

  def query
    model.parse_all(DBConnection.execute(<<-SQL))
      SELECT
        #{select_string}
      FROM
        #{from_string}
      WHERE
        #{where_string}
    SQL
  end

  def results
    @results ||= query
  end

  def method_missing(sym, *args, &block)
    results.send(sym, *args, &block)
  end

  def ==(value)
    results == value
  end

end
