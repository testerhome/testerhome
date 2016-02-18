module API
  module V3
    class Ads < Grape::API
      resource :ads do
        params do
          optional :limit, type: Integer, default: 20, values: 1..150
        end
        get "toutiao" do
          params[:limit] = 100 if params[:limit] > 100
          @ads = Ad.limit(params[:limit])
          render @ads
        end
      end
    end
  end
end