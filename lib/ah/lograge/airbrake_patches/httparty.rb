# add short summary of HTTParty response
module HTTParty
  class ResponseError < Error
    def to_airbrake
      params = {
        params: {
          response: { code: response.code, body: response.body[0..1024] },
          request: {
            uri: response.request.uri.to_s,
            method: response.request.http_method.to_s.demodulize.upcase,
            body: response.request.send(:body),
            basic_auth: response.request.options[:basic_auth],
            headers: response.request.options[:headers]
          }
        }
      }
      # filter sensitive info
      filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
      filter.filter(params)
    end
  end
end
