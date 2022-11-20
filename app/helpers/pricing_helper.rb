# frozen_string_literal: true

module PricingHelper

  def pricing_html(pricing_type, product, account, currency, unit, display_for = nil, options = {})
    Pricing.new(pricing_type, product, account, currency, unit, display_for = nil, options = {}, current_user).return_formatted_price
  end

  class Pricing < ApplicationController # HACK - Pulled in app controller just for that dang `clarencehouse?` bool
    include PricingHelper
    attr_reader :pricing_type, :product, :account, :currency, :unit, :display_for, :options, :current_user, :price

    def initialize(pricing_type, product, account, currency, unit, display_for = nil, options = {}, current_user)
      @pricing_type = pricing_type
      @product = product
      @account = account
      @currency = currency
      @unit = unit
      @display_for = display_for
      @options = options
      @current_user = current_user
    end

    def return_formatted_price
      @price = send(pricing_type) if current_user.can_view_pricing? && current_user.has_role?(retail_pricing_role? || net_pricing_role?)

      return unless price

      helpers.content_tag(:div, class: "product-price") do
        if clarencehouse?
          format_price(human_price)
        elsif pricing_type == :outlet_pricing
          html = helpers.content_tag(:span, outlet_price, class: "#{currency}-price outlet-price line-through discontinued", data: { price: price })
          html += helpers.content_tag(:span, human_price, class: "#{currency}-price", data: { price: price })
          html
        else
          helpers.content_tag(:span, human_price, class: "#{currency}-price", data: { price: price })
        end
      end
    end

    # Ancillary methods
    def retail_pricing_role?
      ("view_retail_pricing_" + currency.to_s).to_sym if ([pricing_type] & [:base_retail, :your_retail, :basic_pricing, :outlet_pricing]).present?
    end

    def net_pricing_role?
      ("view_net_pricing_" + currency.to_s).to_sym if ([pricing_type] & [:piece_base, :your_piece, :base_net, :your_net, :outlet_pricing]).present?
    end

    def your_retail
      product.your_price_retail(account, currency, unit)
    end

    def base_retail
      product.base_price_retail(currency, unit, :single, account)
    end

    def your_net
      current_account.showroom? && !current_user.has_role?(:view_your_net_price) ? nil : product.your_price_net(account, currency, unit)
    end

    def base_net
      product.base_price_net(currency, unit, :single, account)
    end

    def basic_pricing
      product.retail_price(account: account, currency: currency, unit: unit, type: :single)
    end

    def outlet_price
      markup = Markup.find_for_product(account: account, product: product)
      format_price(markup.apply_to(product.outlet_price(account, currency, unit)))
    end

    def uom_display_text?
      if product.measured_unit["uom_display_text"].present?
        return "#{helpers.number_to_currency(price)} #{humanized_currency(currency)} #{product.measured_unit["uom_display_text"]}"
      end
    end

    def sqft_context?
      unit == "sqft" && options["total_sqft"].present?
    end

    def sqft_unit_total
      price * options["total_sqft"].to_f
    end

    def human_price
      humanized_pricing(product, price, currency, display_for, options)
    end

    def humanized_pricing(product, price, currency = :usd, display_for = nil, options = {})
      content = ""

      uom_display_text?

      unit = product.measured_unit["short"]["singular"].downcase
      unit = product.measured_unit["long"]["singular"].downcase if unit == "3 panel"

      if unit == "dblrl"
        price /= product.wallcovering_unit_divisor
        unit = "sglrl"
      end

      if unit == "sglrl" && display_for != :quick
        content = "#{helpers.number_to_currency(price)} #{humanized_currency(currency)} per single roll (#{sold_as_units(product)})"
      elsif unit == "sglrl" && product.product_type == "wallcovering"
        content = helpers.content_tag(:span, "#{helpers.number_to_currency(price)} / ")
        content << helpers.content_tag(:small, "Single Roll #{humanized_currency(currency)}")
      else
        separator = clarencehouse? ? "per" : "/"
        content = "#{helpers.number_to_currency(price)} #{separator} #{unit} #{humanized_currency(currency)}"
      end

      if sqft_context?
        content = helpers.content_tag(:span, "#{helpers.number_to_currency(sqft_unit_total)} #{humanized_currency(currency)} per unit", class: "per_unit_pricing")
        content << helpers.content_tag(:span, "#{helpers.number_to_currency(price)} #{humanized_currency(currency)} per sq.ft.", class: "per_sqft_pricing")
      end

      if options["display_type"] == "available rug pad"
        if sqft_context?
          content = "#{helpers.number_to_currency(sqft_unit_total)} #{humanized_currency(currency)}"
        else
          content = "#{helpers.number_to_currency(price)} #{humanized_currency(currency)}"
        end
      end

      content
    end

    def humanized_currency(currency)
      symbol = currency.to_sym == :usd && current_user.can_view_cad_pricing? || current_account.currency_code == "cad" ? "USD" : ""
      symbol = "CAD" if current_user.can_view_cad_pricing? && currency.to_sym == :cad
      symbol
    end

    # Just to dry up the dynamic method calls on pricing_type a bit
    alias :your_piece :your_net
    alias :piece_base :base_net
    alias :outlet_pricing :basic_pricing
  end
end
