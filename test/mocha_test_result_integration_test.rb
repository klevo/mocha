require 'test_helper'
require 'mocha/standalone'
require 'mocha/backtracefilter'
require 'mocha/test_case_adapter'
require 'execution_point'

class MochaTestResultIntegrationTest < Test::Unit::TestCase

  def test_should_include_expectation_verification_in_assertion_count
    test_result = run_test do
      object = mock()
      object.expects(:message)
      object.message
    end
    assert_equal 1, test_result.assertion_count
  end
  
  def test_should_include_assertions_in_assertion_count
    test_result = run_test do
      assert true
    end
    assert_equal 1, test_result.assertion_count
  end
  
  def test_should_not_include_stubbing_expectation_verification_in_assertion_count
    test_result = run_test do
      object = mock()
      object.stubs(:message)
      object.message
    end
    assert_equal 0, test_result.assertion_count
  end
  
  def test_should_include_expectation_verification_failure_in_failure_count
    test_result = run_test do
      object = mock()
      object.expects(:message)
    end
    assert_equal 1, test_result.failure_count
  end
  
  def test_should_include_unexpected_verification_failure_in_failure_count
    test_result = run_test do
      object = mock()
      object.message
    end
    assert_equal 1, test_result.failure_count
  end
  
  def test_should_include_assertion_failure_in_failure_count
    test_result = run_test do
      flunk
    end
    assert_equal 1, test_result.failure_count
  end
  
  def test_should_display_backtrace_indicating_line_number_where_expects_was_called
    test_result = Test::Unit::TestResult.new
    faults = []
    test_result.add_listener(Test::Unit::TestResult::FAULT, &lambda { |fault| faults << fault })
    execution_point = nil
    run_test(test_result) do
      object = mock()
      execution_point = ExecutionPoint.current; object.expects(:message)
    end
    assert_equal 1, faults.size
    assert_equal execution_point, ExecutionPoint.new(faults.first.location)
  end
  
  def test_should_display_backtrace_indicating_line_number_where_unexpected_method_was_called
    test_result = Test::Unit::TestResult.new
    faults = []
    test_result.add_listener(Test::Unit::TestResult::FAULT, &lambda { |fault| faults << fault })
    execution_point = nil
    run_test(test_result) do
      object = mock()
      execution_point = ExecutionPoint.current; object.message 
    end
    assert_equal 1, faults.size
    assert_equal execution_point, ExecutionPoint.new(faults.first.location)
  end
  
  def test_should_display_backtrace_indicating_line_number_where_failing_assertion_was_called
    test_result = Test::Unit::TestResult.new
    faults = []
    test_result.add_listener(Test::Unit::TestResult::FAULT, &lambda { |fault| faults << fault })
    execution_point = nil
    run_test(test_result) do
      execution_point = ExecutionPoint.current; flunk
    end
    assert_equal 1, faults.size
    assert_equal execution_point, ExecutionPoint.new(faults.first.location)
  end
  
  def run_test(test_result = Test::Unit::TestResult.new, &block)
    test_class = Class.new(Test::Unit::TestCase) do
      include Mocha::Standalone
      include Mocha::TestCaseAdapter
      define_method(:test_me, &block)
    end
    test = test_class.new(:test_me)
    test.run(test_result) {}
    test_result
  end
  
end