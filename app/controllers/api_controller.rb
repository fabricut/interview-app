# frozen_string_literal: true

class ApiController < ApplicationController
  include ApiHelper
  def stock_and_pricing
    ApiHelper.calculate(Product.find(params[:sku]), current_account, current_user, clarencehouse?)
    build_view_attributes
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def build_view_attributes
    ApiHelper.class_variables.map { |cv| eval("#{cv.to_s[1..-1]} = #{cv}") }
  end
end
