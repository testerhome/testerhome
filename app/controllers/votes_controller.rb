# coding: utf-8
class VotesController < ApplicationController
  before_action :require_user
  before_action :find_voteable

  def create
    current_user.vote(@item)
    render text: @item.reload.votes_count
  end

  def destroy
    current_user.unvote(@item)
    render text: @item.reload.votes_count
  end

  private

  def find_voteable
    @success = false
    @element_id = "voteable_#{params[:type]}_#{params[:id]}"
    if !params[:type].in?(%W(Question Answer))
      render text: '-1'
      return false
    end

    case params[:type].downcase
    when 'answer'
      klass = Answer
    else
      return false
    end

    @item = klass.find_by_id(params[:id])
    if @item.blank?
      render text: '-2'
      return false
    end
  end
end
