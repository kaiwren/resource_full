module ActionResource
  module Query
    QUERY_DELIMITER = ','
    
    class << self      
      def included(base)
        super(base)
        base.send(:extend, ClassMethods)
      end
    end
    
    module ClassMethods
      def queryable_with(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        if opts[:from]
          self.joins << opts[:from] 
          opts[:column] = "#{opts[:from].to_s.pluralize}_controller".classify.constantize.resource_identifier
          opts[:table]  = opts[:from].to_s.classify.constantize.table_name
        else
          opts[:table] = self.model_class.table_name
        end
        self.queryable_params = args.collect {|param| QueryParameter.new(param, opts.dup)}
      end
      
      def joins
        @joins ||= []
      end
      
      def queryable_params
        @queryable_params ||= []
      end
      
      def queryable_params=(params)
        @queryable_params = params
      end
    end
    
    def queried_conditions
      query_arrays = self.class.queryable_params.collect do |query_param|
        query_param.conditions_for(params)
      end.reject(&:empty?)
      
      merged_strings = query_arrays.collect {|ary| "(#{ary.shift})"}.join(' AND ')
      
      [ merged_strings ] + query_arrays.sum([])
    end
    
    class QueryParameter
      attr_reader :name, :fuzzy, :columns, :table
      alias_method :fuzzy?, :fuzzy
    
      def initialize(name, opts={})
        
        @name    = name
        @fuzzy   = opts[:fuzzy]
        @table   = opts[:table]
        
        opts[:column] ||= name
        @columns = opts[:columns] || [ opts[:column] ]
      end
      
      def conditions_for(params)
        values = param_values_for(params)
        unless values.empty?
          final_query_string = Array.new(values.size, query_string).join(" OR ")
          final_values       = values.sum([]) { |value| Array.new(columns.size, value) }
          
          [ final_query_string ] + final_values
        else [] end
      end
      
      private
      
        def param_values_for(params)
          values = (params[self.name] || params[self.name.to_s.pluralize] || '').split(',')
          values.map! {|value| "%#{value}%" } if fuzzy?
          values
        end
      
        def query_string
          columns.collect do |column|
            if fuzzy?
              "(#{table}.#{column} LIKE ?)"
            else
              "(#{table}.#{column} = ?)"
            end
          end.join(" OR ")
        end
      
    end
  end
end