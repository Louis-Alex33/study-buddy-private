class CategoriesController < ApplicationController
  def create
    @category = current_user.categories.build(category_params)

    if @category.save
      redirect_back fallback_location: root_path, notice: "Catégorie « #{@category.title} » créée avec succès."
    else
      redirect_back fallback_location: root_path, alert: "Erreur : #{@category.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @category = current_user.categories.find(params[:id])

    if @category.lectures.any? || @category.quizzes.any?
      redirect_back fallback_location: root_path, alert: "Impossible de supprimer une catégorie qui contient des cours ou des quiz."
    else
      @category.destroy
      redirect_back fallback_location: root_path, notice: "Catégorie supprimée."
    end
  end

  private

  def category_params
    params.require(:category).permit(:title)
  end
end
