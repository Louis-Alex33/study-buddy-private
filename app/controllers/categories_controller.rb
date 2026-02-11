class CategoriesController < ApplicationController
  def create
    @category = current_user.categories.build(category_params)

    if @category.save
      redirect_back fallback_location: root_path, notice: t("controllers.categories.created", title: @category.title)
    else
      redirect_back fallback_location: root_path, alert: t("controllers.categories.creation_error", errors: @category.errors.full_messages.join(', '))
    end
  end

  def destroy
    @category = current_user.categories.find(params[:id])

    if @category.lectures.any? || @category.quizzes.any?
      redirect_back fallback_location: root_path, alert: t("controllers.categories.has_content")
    else
      @category.destroy
      redirect_back fallback_location: root_path, notice: t("controllers.categories.destroyed")
    end
  end

  private

  def category_params
    params.require(:category).permit(:title)
  end
end
