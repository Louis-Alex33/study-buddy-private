class SubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:pricing]

  def pricing
  end

  def manage
    @user = current_user
  end

  def checkout
    price_id = if params[:plan] == "annual"
                 ENV["STRIPE_PRO_ANNUAL_PRICE_ID"]
               else
                 ENV["STRIPE_PRO_MONTHLY_PRICE_ID"]
               end

    processor = current_user.set_payment_processor(:stripe)
    checkout_session = processor.checkout(
      mode: "subscription",
      line_items: price_id,
      success_url: subscription_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: pricing_url
    )

    redirect_to checkout_session.url, allow_other_host: true, status: :see_other
  rescue => e
    Rails.logger.error "Checkout error: #{e.message}"
    redirect_to pricing_path, alert: t("controllers.subscriptions.checkout_error")
  end

  def success
    sync_plan_if_needed
    redirect_to lectures_path, notice: t("controllers.subscriptions.welcome_pro")
  end

  def portal
    processor = current_user.payment_processor
    unless processor&.subscription&.active?
      redirect_to subscription_manage_path, alert: t("controllers.subscriptions.no_active_subscription")
      return
    end

    portal_session = processor.billing_portal(
      return_url: subscription_manage_url
    )

    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  rescue => e
    Rails.logger.error "Portal error: #{e.message}"
    redirect_to subscription_manage_path, alert: t("controllers.subscriptions.portal_error")
  end

  private

  def sync_plan_if_needed
    processor = current_user.payment_processor
    return unless processor

    processor.sync_subscriptions
    current_user.sync_plan_from_subscription!
  end
end
