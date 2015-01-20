module Associatable

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      foreign_key_value = send("#{options.foreign_key}")
      target_class = options.model_class
      target_class.where(options.primary_key => foreign_key_value).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      primary_key_value = send("#{options.primary_key}")
      target_class = options.model_class
      target_class.where(options.foreign_key => primary_key_value)
    end
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options =
      self.class.assoc_options[through_name]
      source_options =
      through_options.model_class.assoc_options[source_name]

      foreign_key_value = send("#{through_options.foreign_key}")

      result = DBConnection.execute(<<-SQL, foreign_key_value)
      SELECT
      #{source_options.table_name}.*
      FROM
      #{through_options.table_name}
      JOIN
      #{source_options.table_name}
      ON #{through_options.table_name}.#{source_options.foreign_key}
      = #{source_options.table_name}.#{source_options.primary_key}
      WHERE
      #{through_options.table_name}.#{through_options.primary_key} = ?
      SQL

      source_options.model_class.parse_all(result).first
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class AssocOptions
  attr_accessor(
  :foreign_key,
  :class_name,
  :primary_key
  )

  def model_class
    class_name.to_s.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = options[:foreign_key] || "#{self_class_name.to_s.underscore}_id".to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || name.to_s.camelcase.singularize
  end
end
