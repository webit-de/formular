require 'trailblazer/html/builder'
require 'formular/elements'
require 'formular/path'
module Formular
  module Builders
    # I'm not quite sure why I made this a seperate class
    # But I kind of see myself having Builder as a generic
    # viewbuilder and this basic class as Form
    class Basic < Trailblazer::Html::Builder
      def self.define_element_method(element_name, element_class)
        define_method(element_name) do |*args, &block|
          if args.size > 1
            name_or_content, options = args
          else
            case args.first
            when Symbol, String then name_or_content = args.first
            when Hash then options = args.first
            end
          end

          options ||= {}
          options[:builder] = self
          options[:attribute_name] = name_or_content if name_or_content

          element_class.(options, &block)
        end
      end

      element_set(Trailblazer::Html::Element::VALID_ELEMENT_SET.merge(
        error_notification: Formular::Element::ErrorNotification,
        form: Formular::Element::Form,
        input: Formular::Element::Input,
        hidden: Formular::Element::Hidden,
        label: Formular::Element::Label,
        error: Formular::Element::Error,
        hint: Formular::Element::P,
        textarea: Formular::Element::Textarea,
        submit: Formular::Element::Submit,
        select: Formular::Element::Select,
        checkbox: Formular::Element::Checkbox,
        radio: Formular::Element::Radio,
        wrapper: Formular::Element::Div,
        error_wrapper: Formular::Element::Div
      ))

      def initialize(model: nil, path_prefix: nil, errors: nil, values: nil, elements: {})
        @model = model
        @path_prefix = path_prefix
        @errors = errors || (model ? model.errors : {})
        @values = values || {}
        super(elements)
      end
      attr_reader :model, :errors, :values

      def collection(name, models: nil, builder: nil, &block)
        models ||= model ? model.send(name) : []

        models.map.with_index do |model, i|
          nested(name, nested_model: model, path_appendix: [name,i], builder: builder, &block)
        end.join('')
      end

      def nested(name, nested_model: nil, path_appendix: nil, builder: nil, &block)
        nested_model ||= model.send(name) if model
        path_appendix ||= name
        builder ||= self.class
        builder.new(model: nested_model, path_prefix: path(path_appendix)).(&block)
      end

      # these can be called from an element
      def path(appendix = nil)
        appendix ? Path[*@path_prefix, appendix] : Path[@path_prefix]
      end

      def reader_value(name)
        model ? model.send(name) : values[name.to_sym]
      end
    end # class Basic
  end # module Builders
end # module Formular
