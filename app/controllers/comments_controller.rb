class CommentsController < ApplicationController
  def create
    @status = Status.find(params[:status_id])
    @comment = @status.comments.create(params[:comment].permit(:name, :body))

    redirect_to status_path(@status)
  end

  def destroy
    @status = Status.find(params[:post_id])
    @comment = @status.comments.find(params[:id])
    @comment.destroy

    redirect_to status_path(@status)
  end
end
