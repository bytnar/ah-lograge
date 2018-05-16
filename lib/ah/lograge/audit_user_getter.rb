module Ah
  module Lograge
    module AuditUserGetter
      AUDIT_USER_HEADER_NAME = 'Audit-User'.freeze

      private

      def reject_request_without_audit_user
        # TODO: We will give time for every app requesting documents to prepare for that change
        # render json: { error: "#{AUDIT_USER_HEADER_NAME} header not provided" }, status: 400 if audit_user_uid.blank?
      end

      def audit_user_uid
        @audit_user_uid ||= begin
          if defined?(current_user) && current_user.present?
            current_user.ah_user_uid
          else
            request.headers[AUDIT_USER_HEADER_NAME]
          end
        end
      end
    end
  end
end
