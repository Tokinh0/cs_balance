require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  def execute
    available_cs = filter_and_sort_cs(@customer_success, @away_customer_success)
    customers_by_score = sort_customers(@customers)
    cs_customer_counter = assign_customers_to_cs(available_cs, customers_by_score)
    find_cs_with_most_customers(cs_customer_counter)
  end
  
  def filter_and_sort_cs(customer_success, away_customer_success)
    customer_success.reject { |cs| away_customer_success.include?(cs[:id]) }
                    .sort_by { |cs| cs[:score] }
  end
  
  def sort_customers(customers)
    customers.sort_by { |customer| -customer[:score] }
  end
  
  def assign_customers_to_cs(available_cs, customers_by_score)
    cs_customer_counter = Hash.new(0)
  
    customers_by_score.each do |customer|
      selected_cs = available_cs.bsearch { |cs| cs[:score] >= customer[:score] }
      cs_customer_counter[selected_cs[:id]] += 1 if selected_cs
    end
  
    cs_customer_counter
  end
  
  def find_cs_with_most_customers(cs_customer_counter)
    result = cs_customer_counter.group_by { |id, count| count }
                                .max_by { |count, ids| count }
  
    return 0 unless result && result[1].size == 1
    result[1][0][0]
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
