module Spree
  class MealPreferencesController < Spree::StoreController

    before_action :authorize_user
    before_action :set_meal_preference

    # before_action :vegetarian_and_no_soy, only: [:update, :create]

    def create
      if @meal_preference.update_attributes(meal_preference_params)
        redirect_to spree.account_path
      else
        flash.now[:error] = @meal_preference.errors.full_messages.to_sentence
        render 'index'
      end
    end

    private

      def set_meal_preference
        @meal_preference = spree_current_user.meal_preference || spree_current_user.build_meal_preference
      end

      def meal_preference_params
        params.require(:meal_preference).permit(Spree::MealPreference.diets + Spree::MealPreference.allergens)
      end

      # def vegetarian_and_no_soy
      #   if @meal_preference.allergen_soybeans && (@meal_preference.diet_tofu || @meal_preference.diet_tempeh)
      #     flash[:error] = "If you don’t eat soybeans, then you probably shouldn’t select tofu or tempeh."
      #     redirect_to meal_preferences_path
      #   end
      # end

      def authorize_user
        unless spree_current_user.present?
          store_location
          redirect_to login_path
          return
        end
      end

  end
end
