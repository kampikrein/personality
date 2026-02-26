module Admin
  class BaseController < ApplicationController
    skip_before_action :require_session!

    http_basic_authenticate_with(
      name: ENV.fetch("ADMIN_USERNAME", "admin"),
      password: ENV.fetch("ADMIN_PASSWORD") { Rails.env.production? ? (raise "ADMIN_PASSWORD is required") : "dev-admin-password" },
      realm: "Admin"
    )

    layout "admin"
  end
end
