class Test::Unit::TestCase
  class << self
    attr_accessor :before_each_callbacks, :before_all_callbacks, :after_each_callbacks, :after_all_callbacks

    # Add logic to run before the tests (i.e., a +setup+ method)
    #
    #     before do
    #       @user = User.first
    #     end
    # 
    def before(period = :each, &block)
      send("before_#{period}_callbacks") << block
    end
    
    # Add logic to run after the tests (i.e., a +teardown+ method)
    #
    #     after do
    #       User.delete_all
    #     end
    #
    def after(period = :each, &block)
      send("after_#{period}_callbacks") << block
    end

    def gather_callbacks(callback_type, period)
      callbacks = superclass.respond_to?(:gather_callbacks) ? superclass.gather_callbacks(callback_type, period) : []
      callbacks.push(*send("#{callback_type}_#{period}_callbacks"))
    end
  end

  self.before_all_callbacks  = []
  self.before_each_callbacks = []
  self.after_each_callbacks  = []
  self.after_all_callbacks   = []

  def self.inherited(child)
    super
    child.before_all_callbacks  = []
    child.before_each_callbacks = []
    child.after_each_callbacks  = []
    child.after_all_callbacks   = []

    child.class_eval do
      def setup
        run_each_callbacks :before
      end

      def teardown
        run_each_callbacks :after
      end
    end
  end

  def run_each_callbacks(callback_type)
    self.class.gather_callbacks(callback_type, :each).each { |c| instance_eval(&c) }
  end

  def run_all_callbacks(callback_type)
    previous_ivars = instance_variables
    self.class.gather_callbacks(callback_type, :all).each { |c| instance_eval(&c) }
    (instance_variables - previous_ivars).inject({}) do |hash, ivar|
      hash.update ivar => instance_variable_get(ivar)
    end
  rescue Object => exception
    raise <<-BANG
Error running the #{callback_type}(:all) callback for #{name}
#{exception.class.name}: #{exception.message}
#{exception.backtrace.join("\n")}
    BANG
  end

  def set_values_from_callbacks(values)
    values.each do |name, value|
      instance_variable_set name, value
    end
  end
end