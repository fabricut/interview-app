# frozen_string_literal: true

module ApiHelper
  def self.calculate(product, account, current_user, ch_bool)
    {
      pricing: {
        retail: {
          base: {
            usd: product.base_price__retail(:usd, :unit, :single),
            cad: product.base_price__retail(:cad, :unit, :single)
          },
          markup: {
            usd: product.retail_price(account: account, currency: :usd, unit: :unit, type: :single),
            cad: product.retail_price(account: account, currency: :cad, unit: :unit, type: :single)
          },
          customer: {
            usd: product.your_price_retail(account, :usd, :unit),
            cad: product.your_price_retail(account, :cad, :unit)
          }
        },
        net: {
          base: {
            usd: product.base_price__net(:usd, :unit, :single),
            cad: product.base_price__net(:cad, :unit, :single)
          },
          account_cost: {
            usd: product.your_price_net(account, :usd, :unit),
            cad: product.your_price_net(account, :cad, :unit)
          },
          piece: {
            usd: product.your_price_net(account, :usd, :piece),
            cad: product.your_price_net(account, :cad, :piece)
          },
          halfpiece: {
            usd: product.your_price_net(account, :usd, :halfpiece),
            cad: product.your_price_net(account, :cad, :halfpiece)
          },
          customer: {
            unit: product.order_price__net(current_user, :unit),
            piece: product.order_price__net(current_user, :piece),
            halfpiece: product.order_price__net(current_user, :halfpiece)
          }
        }
      },
      stock: product.stock(current_user)&.merge(unit: product.measured_unit)
    }.tap do |hash|
      hash[:uom_display_text] = product.measured_unit["uom_display_text"] if product.measured_unit["uom_display_text"].present?

      if product.wallcovering?
        hash[:measured_unit] = product.measured_unit["long"]["singular"].downcase
        hash[:order_increment] = product.wallcovering_data.average_bolt.to_f
      end

      hash[:pricing].delete(:net) unless current_user.can_view_net_pricing?
      hash.delete(:stock) unless current_user.has_role?(:view_stock)
      view_objects(hash, product, ch_bool)
    end
  end

  def self.view_objects(hash, product, ch_bool)
    @@product = product
    @@stock_output = hash[:stock].deep_symbolize_keys
    @@stock_total = @@stock_output[:current][:total]
    @@stock_unit = @@stock_output[:unit][:long][@@stock_total == 1 ? :singular : :plural]
    @@stock_total_reserved = @@stock_output[:total_reserved]
    @@stock_total_reserved_unit = @@stock_output[:unit][:long][@@stock_total_reserved == 1 ? :singular : :plural]
    @@has_stock = @@stock_total.present? && @@stock_total.to_f.positive?
    @@has_availability = @@stock_output[:availability].present?
    @@incoming_stock = @@stock_output[:expected]
    @@bolts = @@stock_output[:current][:bolts]

    # 
    clarencehouse_edge_case(ch_bool)
    # 
    @@regular_bolts_dye_lots = @@regular_bolts.group_by { |_bolt, lot| lot[:dye_lot] } if @@regular_bolts.present?
    @@small_cuts_dye_lots = @@small_cuts.group_by { |_bolt, lot| lot[:dye_lot] } if @@small_cuts.present?
  end

  def self.clarencehouse_edge_case(ch_bool)
    # Small cuts applies to fabric sold by the yard, excluding Clarencehouse
    if ch_bool && @@product.fabric? && @@product.measured_unit["long"]["singular"] == "Yard"
      @@regular_bolts, @@small_cuts = @@bolts.partition { |_bolt, lot| lot[:quantity].to_f >= 5 } if @@bolts.present?
    else
      @@regular_bolts = @@bolts
      @@small_cuts = nil
    end
  end
end
