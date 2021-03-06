module Spree
  class User::MealPreferencesController < Spree::StoreController
    include ControllerHelpers::UserAuth

    before_action :authorize_user
    before_action :set_meal_preference

    def create
      if @meal_preference.update_attributes(meal_preference_params)
        UserAccountMailer.meal_preferences_changed_email(@meal_preference).deliver_later
        redirect_to spree.account_path
      else
        flash.now[:error] = @meal_preference.errors.full_messages.join(" ")
        render 'show'
      end
    end

    private

      def set_meal_preference
        @meal_preference = spree_current_user.meal_preference || spree_current_user.create_meal_preference
      end

      def meal_preference_params
        params.require(:meal_preference).permit(Spree::MealPreference.diets + Spree::MealPreference.allergens)
      end

  end
end
