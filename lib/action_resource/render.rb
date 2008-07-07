module ActionResource
  module Render
    def self.included(controller)
      controller.rescue_from Exception, :with => :handle_generic_exception_with_correct_response_format
    end
    
    protected
    
      def show_xml
        self.model_object = send("find_#{model_name}")
        render :xml => model_object
      rescue ActiveRecord::RecordNotFound => e
        render :xml => e.to_xml, :status => :not_found
      end
    
      def index_xml
        self.model_objects = send("find_all_#{model_name.pluralize}")
        render :xml => model_objects
      end
    
      def create_xml
        self.model_object = send("create_#{model_name}")
        if model_object.valid?
          head :created, :location => send("#{model_name}_url", model_object.id)
        else
          render :xml => model_object.errors, :status => status_for(model_object.errors)
        end
      end
    
      def update_xml
        self.model_object = send("update_#{model_name}")      
        if model_object.valid?
          render :xml => model_object
        else
          render :xml => model_object.errors, :status => status_for(model_object.errors)
        end
      rescue ActiveRecord::RecordNotFound => e
        render :xml => e.to_xml, :status => :not_found
      end
    
      def destroy_xml
        self.model_object = send("destroy_#{model_name}")
        head :ok
      rescue ActiveRecord::RecordNotFound => e
        render :xml => e.to_xml, :status => :not_found
      end
  
      def show_html
        self.model_object = send("find_#{model_name}")
      rescue ActiveRecord::RecordNotFound => e
        flash[:error] = e.message
      end
    
      def index_html
        self.model_objects = send("find_all_#{model_name.pluralize}")
      end
    
      def create_html
        self.model_object = send("create_#{model_name}")
        if model_object.valid?
          flash[:info] = "Successfully created #{model_name.humanize} with ID of #{model_object.id}."
          redirect_to :action => :index, :format => :html
        else
          render :action => "new"
        end
      end
    
      def update_html
        self.model_object = send("update_#{model_name}")      
        if model_object.valid?
          flash[:info] = "Successfully updated #{model_name.humanize} with ID of #{model_object.id}."
          redirect_to :action => :index, :format => :html
        else
          render :action => "edit"
        end
      end
    
      def destroy_html
        self.model_object = send("destroy_#{model_name}")
        flash[:info] = "Successfully destroyed #{model_name.humanize} with ID of #{params[:id]}."
        redirect_to :action => :index, :format => html
      rescue ActiveRecord::RecordNotFound => e
        flash[:error] = e.message
        redirect_to :back
      end
      
      def handle_generic_exception_with_correct_response_format(exception)
        if request.format.xml?
          render :xml => exception.to_xml
        else
          rescue_action_with_handler(exception)
        end
      end
  
    private
  
      CONFLICT_MESSAGE = if defined?(ActiveRecord::Errors) 
        ActiveRecord::Errors.default_error_messages[:taken]
      else 
        "has already been taken"
      end

      def status_for(errors)
        if errors.any? { |message| message.include? CONFLICT_MESSAGE }
          :conflict
        else :unprocessable_entity end
      end
  end
end