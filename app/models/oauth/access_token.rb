#  Copyright (c) 2019-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: oauth_access_tokens
#
#  id                     :integer          not null, primary key
#  expires_in             :integer
#  previous_refresh_token :string           default(""), not null
#  refresh_token          :string
#  revoked_at             :datetime
#  scopes                 :string
#  token                  :string           not null
#  created_at             :datetime         not null
#  application_id         :integer
#  resource_owner_id      :integer
#
# Indexes
#
#  index_oauth_access_tokens_on_refresh_token      (refresh_token) UNIQUE
#  index_oauth_access_tokens_on_resource_owner_id  (resource_owner_id)
#  index_oauth_access_tokens_on_token              (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (application_id => oauth_applications.id)
#

module Oauth
  class AccessToken < Doorkeeper::AccessToken
    belongs_to :person, foreign_key: :resource_owner_id, inverse_of: :access_tokens
    belongs_to :application, class_name: "Oauth::Application"

    scope :list, -> { order(created_at: :desc) }
    # no need to check expires_in as refresh_token would never expire
    scope :active, -> { where(revoked_at: nil) }

    devise

    def to_s
      token
    end
  end
end
