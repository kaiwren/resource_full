module ResourceFull
  module Query
    QUERY_DELIMITER = ','
    
    class << self      
      def included(base)
        super(base)
        base.send :extend, ClassMethods
      end
    end
    
    module ClassMethods
      # Indicates that the resource should be queryable with the given parameters, which will be pulled from
      # the params hash on an index or count call.  Accepts the following options:
      # 
      #   * :fuzzy => true : Use a LIKE query instead of =.
      #   * :columns / :column => ... : Override the default column, or provide a list of columns to query for this value.
      #   * :from => :join_name : Indicate that this value should be queried by joining on another model.  Should use
      #     a valid relationship from this controller's exposed model (e.g., :account if belongs_to :account is specified.)
      #   * :resource_identifier => true : Try to look up the resource controller for this value and honor its
      #     specified resource identifier.  Useful for nesting relationships.
      #
      # Examples:
      #
      #   queryable_with :user_id
      #   queryable_with :body, :fuzzy => true
      #   queryable_with :name, :columns => [:first_name, :last_name]
      #   queryable_with :street_address, :from => :address
      #
      # TODO No full-text search support.
      def queryable_with(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        self.queryable_params += args.collect {|param| ResourceFull::Query::Parameter.new(param, self, opts.dup)}
      end
      
      # :nodoc:
      def joins
        @joins ||= []
      end
      
      # All queryable parameters.  Objects are of type ResourceFull::Query::Parameter.
      def queryable_params
        @queryable_params ||= []
      end
      
      # :nodoc:
      def queryable_params=(params)
        @queryable_params = params
      end
      
      def nests_within(*resources)
        resources.each do |resource|
          expected_nest_id = "#{resource.to_s.singularize}_id"
          queryable_with expected_nest_id, :from => resource.to_sym, :resource_identifier => true
        end
      end
    end
    
    def queried_conditions
      query_arrays = self.class.queryable_params.collect do |query_param|
        query_param.conditions_for(params)
      end.reject(&:empty?)
      
      merged_strings = query_arrays.collect {|ary| "(#{ary.shift})"}.join(' AND ')
      
      [ merged_strings ] + query_arrays.sum([])
    end
  end
end