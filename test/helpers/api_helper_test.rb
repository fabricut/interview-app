require 'test_helper'

class ApiHelperTest < ActionView::TestCase
  def setup
    @subject = subject
  end

  def subject
    ApiHelper.calculate(products(:test), users.first.accounts.first, users.first, false)
  end

  test 'payload happy path' do
    expected_payload = {:pricing=>{:retail=>{:base=>{:usd=>38.0, :cad=>64.6}, :markup=>{:usd=>19.0, :cad=>32.5}, :customer=>{:usd=>19.0, :cad=>32.5}}, :net=>{:base=>{:usd=>19.0, :cad=>32.3}, :account_cost=>{:usd=>19.0, :cad=>32.3}, :piece=>{:usd=>11.95, :cad=>nil}, :halfpiece=>{:usd=>12.45, :cad=>nil}, :customer=>{:unit=>19.0, :piece=>19.0, :halfpiece=>19.0}}}, :stock=>{"current"=>{"bolts"=>{"1971"=>{"dye_lot"=>"0", "quantity"=>27.73}, "473563"=>{"dye_lot"=>"0", "quantity"=>60.0}, "473564"=>{"dye_lot"=>"0", "quantity"=>60.0}, "473565"=>{"dye_lot"=>"0", "quantity"=>60.0}, "473566"=>{"dye_lot"=>"0", "quantity"=>60.0}, "473567"=>{"dye_lot"=>"0", "quantity"=>60.0}, "473568"=>{"dye_lot"=>"0", "quantity"=>60.0}, "473569"=>{"dye_lot"=>"0", "quantity"=>60.0}}, "memos"=>1, "total"=>447}, "expected"=>[], "availability"=>"", "total_reserved"=>0.0, :unit=>{"short"=>{"singular"=>"Yd", "plural"=>"Yds"}, "long"=>{"singular"=>"Yard", "plural"=>"Yards"}, "uom_display_text"=>nil}}}

    assert_equal expected_payload, @subject
  end

  test 'view attributes happy path' do
    expected_class_variables = [:@@product, :@@stock_output, :@@stock_total, :@@stock_unit, :@@stock_total_reserved, :@@stock_total_reserved_unit, :@@has_stock, :@@has_availability, :@@incoming_stock, :@@bolts, :@@regular_bolts, :@@small_cuts, :@@regular_bolts_dye_lots]

    assert_equal expected_class_variables, ApiHelper.class_variables
  end

  test 'a sample of view attribute assignment' do
    expected = [:"1971", {:dye_lot=>"0", :quantity=>27.73}]

    assert_equal expected, @@bolts.first
  end

  test 'mass assignment of view attributes' do
    ApiHelper.class_variables.each do |class_var|
      refute_empty(class_var, "Class variable: #{class_var} not declared")
    end
  end
end
