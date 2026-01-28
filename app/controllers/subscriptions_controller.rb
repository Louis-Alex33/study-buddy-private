class SubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:pricing]

  def pricing
  end

  def checkout
    checkout_session = current_user.payment_processor.checkout(
      mode: "subscription",
      line_items: ENV["STRIPE_PRO_MONTHLY_PRICE_ID"],
      success_url: subscription_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: pricing_url
    )

    redirect_to checkout_session.url, allow_other_host: true, status: :see_other
  end

  def success
    sync_plan_if_needed
    redirect_to lectures_path, notice: "Bienvenue dans Studigo Pro ! Profitez de toutes les fonctionnalites."
  end

  def portal
    portal_session = current_user.payment_processor.billing_portal(
      return_url: lectures_url
    )

    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  end

  private

  def sync_plan_if_needed
    current_user.payment_processor.sync_subscriptions
    current_user.sync_plan_from_subscription!
  end
end
