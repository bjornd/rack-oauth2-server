require "rack/oauth2/server"

module Rack
  module OAuth2

    # Rails support.
    #
    # Adds oauth instance method that returns Rack::OAuth2::Helper, see there for
    # more details.
    #
    # Adds oauth_required filter method. Use this filter with actions that require
    # authentication, and with actions that require client to have a specific
    # access scope.
    #
    # Adds oauth setting you can use to configure the module (e.g. setting
    # available scopes, see example).
    #
    # @example config/environment.rb
    #   require "rack/oauth2/rails"
    #
    #   Rails::Initializer.run do |config|
    #     config.oauth[:scopes] = %w{read write}
    #     config.oauth[:authenticator] = lambda do |username, password|
    #       User.authenticated username, password
    #     end
    #     . . .
    #   end
    #
    # @example app/controllers/my_controller.rb
    #   class MyController < ApplicationController
    #
    #     oauth_required :only=>:show
    #     oauth_required :only=>:update, :scope=>"write"
    #
    #     . . .
    #
    #   protected 
    #     def current_user
    #       @current_user ||= User.find(oauth.resource) if oauth.authenticated?
    #     end
    #   end
    module Rails

      # Helper methods available to controller instance and views.
      module Helpers
        # Returns the OAuth helper (Rack::OAuth2::Helper)
        def oauth
          @oauth ||= Rack::OAuth2::Server::Helper.new(request, response)
        end
      end

      # Filter methods available in controller.
      module Filters
        def oauth_required(options = {})
          scope = options.delete(:scope)
          before_filter options do |controller|
            if controller.oauth.authenticated?
              if scope && !controller.oauth.scope.include?(scope)
                controller.send :head, controller.oauth.no_scope!(scope)
              end
            else
              controller.send :head, controller.oauth.no_access!
            end
          end
        end
      end

      # Configuration methods available in config/environment.rb.
      module Configuration
        def oauth
          @oauth ||= { :logger=>::Rails.logger }
        end
      end

    end

  end
end

class Rails::Configuration
  include Rack::OAuth2::Rails::Configuration
end
class ActionController::Base
  helper Rack::OAuth2::Rails::Helpers
  include Rack::OAuth2::Rails::Helpers
  extend Rack::OAuth2::Rails::Filters
end
# Add middleware now, but load configuration as late as possible.
ActionController::Dispatcher.middleware.use Rack::OAuth2::Server, lambda { Rails.configuration.oauth }