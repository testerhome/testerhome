# coding: utf-8
class SearchController < ApplicationController
  def index
    keywords = params[:q] || ''
    keywords.gsub!('#', '%23')
    redirect_to "http://www.baidu.com/#wd=site%3A(testerhome.com)+#{keywords}"
  end
end
