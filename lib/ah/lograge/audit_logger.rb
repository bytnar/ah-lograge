# Each action on PII data (resources are one of them) needs to be auditable according to GDPR regulation
# Log is send in established format which will be stored as long as required
# Log format:
# tagged with 'AUDIT'
# required fields:
# audit_user - unique and descriptive user data
# audit_action - type of operation performed on sensitive resource
# audit_resource - unique resource identifier
# audit_request_source - app which is making the request

# frozen_string_literal: true
module Ah
  module Lograge
    class AuditLogger
      AUDIT_TAG = 'AUDIT'
      DEFAULT_APP = 'self'
      ACTION_GET = 'GET'
      ACTION_DELETE = 'DELETE'
      ACTION_UPDATE = 'UPDATE'
      ACTION_CREATE = 'CREATE'
      SYMBOL_TO_ACTION = {
        get: ACTION_GET,
        delete: ACTION_DELETE,
        update: ACTION_UPDATE,
        create: ACTION_CREATE
      }.freeze

      class << self
        #
        # Save audit log containing information about user accessing sensitive resource.
        #
        # @param [Resource] resource - accessed resource by user
        # @param [Symbol] action - type of operation performed on sensitive resource (GET/DELETE/UPDATE/CREATE)
        # @param [String] requester - unique user ID - e.g. OAUTHID (if action is triggered by external application,
        #                              user ID must be passed (client application must also add
        #                              "user" field in the request) so it can be logged in
        #                              destination application - situation when user name is lost
        #                              and only external_application_name is logged is unacceptable)
        #
        # @param [String] app - source of the request - if it is external request (from external application)
        #                       name of that application must be placed / when request is local "self" must be placed
        #

        def log_resource_action(resource:, action:, requester:, customer_uid:, app: DEFAULT_APP)
          logger.tagged(AUDIT_TAG) do
            logger.info(
              audit_requester_uid: requester,
              audit_action: SYMBOL_TO_ACTION[action],
              audit_request_source: app,
              audit_resource: resource.as_json,
              audit_customer_uid: customer_uid
            )
          end
        end

        #
        # Save audit logs for multiple resources
        #
        # @param [Array[Resource]] resources - array of accessed resource by user
        # @param [Symbol] action - type of operation performed on sensitive resource (GET/DELETE/UPDATE/CREATE)
        # @param [String] requester - unique user ID - e.g. OAUTHID (if action is triggered by external application,
        #                              user ID must be passed (client application must also add
        #                              "user" field in the request) so it can be logged in
        #                              destination application - situation when user name is lost
        #                              and only external_application_name is logged is unacceptable)
        #
        # @param [String] app - source of the request - if it is external request (from external application)
        #                       name of that application must be placed / when request is local "self" must be placed
        #
        def log_resources_action(resources:, action:, requester:, customer_uid:, app: DEFAULT_APP)
          resources.each do |resource|
            log_resource_action(
              resource: resource,
              action: action,
              requester: requester,
              customer_uid: customer_uid,
              app: DEFAULT_APP
            )
          end
        end

        def logger
          @@_logger ||= if defined?(Rails) && Rails.respond_to?(:logger)
            Rails.logger
          else
            ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
          end
        end
      end
    end
  end
end
