class MealSelector
  attr_reader :meal_preferences

  # Initializes a meal selector to create a set of selections matching all preferences and
  # subscriptions from available meals. It relates subscriptions to meal preferences by
  # the user_id field of each. Available meals must be a hash of meal => available stock.
  def initialize(subscriptions=[], available_meals={})
    @subscriptions = subscriptions.index_by(&:user_id)
    @available_meals = available_meals
  end

  def meal_preferences
    Spree::MealPreference.where(user_id: @subscriptions.keys).sort_by { |mp| mp.diet_count - mp.allergen_count }
  end

  def selections(no_repeats_last_n_orders=3)
    @selections ||= generate_selections(no_repeats_last_n_orders)
  end

  private

    def generate_selections(last_n)
      selections = {}

      meal_preferences.each do |meal_preference|
        # Verify subscription is active
        subscription = @subscriptions[meal_preference.user_id]
        next unless subscription.present?
        next unless subscription.active?

        # Attempt to fill meal_count items from @available_meals for the subscription
        sub_selections = []
        subscription.meal_count.times do |n|
          @available_meals.each do |meal, stock|
            next unless stock > 0                                     # skip meal when out of stock
            next unless meal_preference.allowed?(meal)                # skip meal when preferences don't match
            next if sub_selections.include? meal                      # skip meal if already selected for this subscription
            next if subscription.user.recently_ordered?(meal, last_n) # skip meal if ordered recently
            sub_selections << meal                                    # select meal and reduce stock
            @available_meals[meal] -= 1
            break
          end
        end
        sub_selections << nil while sub_selections.size < subscription.meal_count # note unfilled meal slots for a subscription
        selections[subscription] = sub_selections
      end

      selections
    end

end
