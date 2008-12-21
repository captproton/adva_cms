module With
  class Group
    def it_changes(expressions, message = nil)
      expressions.each do |expression, difference|
        before { record_before_state(expression) }
        assertion "it changes #{expression} by #{difference}" do
          assert_state_change(expression, difference, message)
        end
      end
    end
    
    def it_does_not_change(*expressions)
      expressions.each do |expression|
        before { record_before_state(expression) }
        assertion "it does not change #{expression}" do
          assert_no_state_change(expression)
        end
      end
    end
    
    def it_updates(*names)
      names.each do |name|
        before { record_before_state("@#{name}.attributes") }
        assertion "it updates #{name}" do
          previous = @before_states["@#{name}.attributes"]
          current = assigns(name).reload.attributes
          assert_not_equal previous, current, "expected #{name} to be updated, but wasn't"
        end
      end
    end
    
    def it_destroys(name)
      assertion "it destroys #{name}" do
        record = assigns(name) || instance_variable_get("@#{name}")
        assert_raises ActiveRecord::RecordNotFound do
          name.to_s.classify.constantize.find(record.id)
        end
      end
    end
    
    def it_versions(*names)
      names.each do |name|
        before { record_before_state("@#{name}.version") }
        assertion "it versions #{name}" do
          previous = @before_states["@#{name}.version"]
          current  = assigns(name).reload.version
          message  = "expected #{name} to be versioned (changed from #{previous} to #{current}), but wasn't"
          assert_equal previous + 1, current, message
        end
      end
    end
    
    def it_does_not_version(*names)
      names.each do |name|
        before { record_before_state("@#{name}.version") }
        assertion "it versions #{name}" do
          previous = @before_states["@#{name}.version"]
          current  = assigns(name).reload.version
          message  = "expected #{name} not to be versioned,  but was (changed from #{previous} to #{current})"
          assert_equal previous, current, message
        end
      end
    end
    
    def it_rollsback(name, options)
      expected = options[:to] or raise "need to pass the target version as an option"
      assertion "it rollsback the #{name} to version #{expected}" do
        actual  = assigns(name).reload.version
        message = "expected #{name} to be rolledback to version #{expected}, but was #{actual}"
        assert_equal expected, actual, message
      end
    end
    
    def it_does_not_rollback(name)
      before { record_before_state("@#{name}.version") }

      assertion "it does not rollback the #{name}" do
        previous = @before_states["@#{name}.version"]
        current  = assigns(name).reload.version
        message  = "expected #{name} not to be rolledback from version #{previous}, but was #{current}"
        assert_equal previous, current, message
      end
    end
  end
end

class ActionController::TestCase
  def it_saves(*names)
    names.each do |name|
      assert !assigns(name).new_record?
    end
  end

  def it_does_not_save(*names)
    names.each do |name|
      assert assigns(name).new_record?
    end
  end

  protected
  
    def record_before_state(expression)
      @before_states ||= {}
      @before_states[expression] = instance_eval(expression)
    end
  
    def assert_state_change(expression, difference, message = nil)
      expected = @before_states[expression] + difference
      result   = instance_eval(expression)
      message  = [message, "expected #{expression} to be #{expected} but was #{result}"]
    
      assert_equal expected, result, message.compact.join("\n")
    end
  
    def assert_no_state_change(expression)
      expected = @before_states[expression]
      result   = instance_eval(expression)
      message  = "expected #{expression} to not change, but changed from #{expected} to #{result}"
    
      assert_equal expected, result, message
    end
end

