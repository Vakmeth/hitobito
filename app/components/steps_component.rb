# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class StepsComponent < ApplicationComponent
  renders_many :headers, 'HeaderComponent'
  renders_many :steps, 'StepComponent'

  attr_accessor :step, :partials

  def initialize(step:, form:, partials: [])
    @partials = partials
    @step = step
    @form = form
  end

  def render?
    @partials.present?
  end

  class IteratingComponent < ApplicationComponent
    attr_reader :current_step

    delegate :index, :first?, :last?, to: '@iterator'

    def initialize(step:, iterator:)
      @step = step
      @iterator = iterator
    end

    private

    def active_class
      'active' if active?
    end

    def active?
      index == @step
    end

    def stimulus_controller
      StepsComponent.name.underscore.gsub('/', '--').tr('_', '-')
    end
  end

  class HeaderComponent < IteratingComponent
    def initialize(header:, header_iteration:, step:)
      super(iterator: header_iteration, step: step)
      @header = header
    end

    def call
      content_tag(:li, markup,
                  class: active_class,
                  data: stimulus_target('stepHeader'))
    end

    def render?
      !(first? && last?)
    end

    private

    def markup
      title
    end

    def title
      ti("#{@header}_title")
    end
  end

  class ContentComponent < IteratingComponent
    with_collection_parameter :partial

    public :stimulus_action

    def initialize(partial:, partial_iteration:, step:, form:)
      super(iterator: partial_iteration, step: step)
      @form = form
      @partial = partial.to_s
    end

    def call
      content_tag(:div, markup,
                  class: %W[step-content #{@partial.dasherize} #{active_class}],
                  data: stimulus_target('stepContent'))
    end

    def next_button(title = nil, options = {})
      type = 'submit'
      title ||= I18n.t("#{@partial.gsub('/', '.')}.next_button", default: nil)
      title ||= if last?
                  t('groups.self_registration.form.submit')
                else
                  t('steps_component.next_link')
                end
      submit_button(title, type, next_submit_button_options.merge(options))
    end

    def submit_button(label, type, options)
      content_tag(:div, class: 'btn-group') do
        helpers.add_css_class(options, 'btn btn-sm btn-primary mt-2')
        @form.button(label, options.merge(type: type, data: { disable_with: label }))
      end
    end

    def back_link
      data = { action: stimulus_action(:back), index: index - 1 }
      link_to(t('global.button.back'), '#', class: 'link cancel mt-2 pt-1', data: data)
    end

    def render?
      index <= @step
    end

    private

    def next_submit_button_options
      options = past? ? { formnovalidate: true } : {}
      options.merge(name: :next, value: index + 1)
    end

    def past?
      index < @form.object.step
    end

    def markup
      render(@partial, f: @form, c: self, required: false)
    end
  end
end
