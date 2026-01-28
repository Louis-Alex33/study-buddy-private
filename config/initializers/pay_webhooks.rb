Rails.application.config.to_prepare do
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.created" do |event|
    pay_subscription = Pay::Subscription.find_by(processor_id: event.data.object.id)
    next unless pay_subscription

    user = pay_subscription.customer.owner
    user.update!(plan: "pro") if user.is_a?(User)
  end

  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.updated" do |event|
    pay_subscription = Pay::Subscription.find_by(processor_id: event.data.object.id)
    next unless pay_subscription

    user = pay_subscription.customer.owner
    next unless user.is_a?(User)

    if pay_subscription.active?
      user.update!(plan: "pro")
    else
      user.update!(plan: "free")
    end
  end

  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.deleted" do |event|
    pay_subscription = Pay::Subscription.find_by(processor_id: event.data.object.id)
    next unless pay_subscription

    user = pay_subscription.customer.owner
    user.update!(plan: "free") if user.is_a?(User)
  end
end
