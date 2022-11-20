require 'test_helper'

class PricingHelperTest < ActionView::TestCase
  def subject(pricing_type, iso_4217)
    subject = PricingHelper::Pricing.new(pricing_type, products(:test), users.first.accounts.first, iso_4217, :unit, users.first).return_formatted_price

    # Cheap way for cleaner specs, probably overkill all things considered.
    Nokogiri(subject).text
  end

  test 'USD retail price' do
    assert_equal "$19.00 / yd USD", subject(:basic_pricing, :usd)
  end

  test 'CAD retail price' do
    assert_equal "$32.50 / yd CAD", subject(:basic_pricing, :cad)
  end

  test 'USD base net' do
    assert_equal "$19.00 / yd USD", subject(:base_net, :usd)
  end

  test 'CAD base net' do
    assert_equal "$32.30 / yd CAD", subject(:base_net, :cad)
  end

  test 'a pricing format that does not exist' do
    # OFI - The code tested in this spec should return a custom error like NoPricingFormatError or something
    assert_raise(NoMethodError) { subject(:foo, :cad) }
  end

  test 'a currency code that does not exist' do
    # OFI - The code tested in this spec should return a custom error like NoCurrencyCodeError or something
    assert_raise(NoMethodError) { subject(:basic_pricing, :foo) }

    # TDD start point
    # assert_raise(NoCurrencyCodeError) { subject(:basic_pricing, :foo) }
  end
end
