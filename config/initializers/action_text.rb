# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# See https://github.com/rails/rails/issues/37672 - this issue was affecting the specs
ActiveSupport.on_load(:action_view) do
  include ActionText::ContentHelper
  include ActionText::TagHelper
end

Rails.application.config.after_initialize do

  # Only allow tags that are supported in Trix.
  # List based on the following files in Trix:
  # https://github.com/basecamp/trix/blob/master/src/trix/config/block_attributes.coffee
  # https://github.com/basecamp/trix/blob/master/src/trix/config/text_attributes.coffee
  ActionText::ContentHelper.allowed_tags = Set.new([
      "div",
      "blockquote",
      "h1",
      "pre",
      "ul",
      "ol",
      "li",
      "strong",
      "em",
      "a",
      "del",
      Rails.application.config.action_text.attachment_tag_name,
      "figure",
      "figcaption",
      "img",
      "br"
  ]).freeze
end
