require 'representable'
require 'representable/xml/binding'
require 'representable/xml/collection'
require 'nokogiri'

module Representable
  module XML
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        self.representation_wrap = true # let representable compute it.
        register_feature Representable::XML
      end
    end


    module ClassMethods
      def remove_namespaces!
        representable_attrs.options[:remove_namespaces] = true
      end

      def namespaces(namespaces)
        representable_attrs.options[:namespaces] = namespaces
      end

      def default_namespace(namespace)
        representable_attrs.options[:default_namespace] = namespace
      end

      def namespace(namespace)
        representable_attrs.options[:namespace] = namespace
      end

      def collection_representer_class
        Collection
      end
    end

    def from_xml(doc, *args)
      node = parse_xml(doc, *args)

      from_node(node, *args)
    end

    def from_node(node, options={})
      add_namespaces(node)
      update_properties_from(node, options, Binding)
    end

    # Returns a Nokogiri::XML object representing this object.
    def to_node(options={})
      options[:doc] ||= Nokogiri::XML::Document.new
      root_tag = options[:wrap]
      if root_tag.blank?
        root_tag = representation_wrap(options)
        root_tag = "#{namespace}:#{root_tag}" unless namespace.blank?
      end
      node = create_node(root_tag.to_s, options[:doc])
      create_representation_with(node, options, Binding)
    end

    def to_xml(*args)
      to_node(*args).to_s
    end

    def namespace
      representable_attrs.options[:namespace]
    end

    def namespaces
      representable_attrs.options.fetch(:namespaces, {})
    end

    def default_namespace
      representable_attrs.options[:default_namespace]
    end

  private
    def remove_namespaces?
      # TODO: make local Config easily extendable so you get Config#remove_ns? etc.
      representable_attrs.options[:remove_namespaces]
    end

    def parse_xml(doc, *args)
      node = Nokogiri::XML(doc)

      node.remove_namespaces! if remove_namespaces?
      node.root
    end

    def create_node(name, document)
      node = Nokogiri::XML::Node.new(name, document)
      if default_namespace.present?
        node.default_namespace = default_namespace
      end
      add_namespaces(node)
      node
    end

    def add_namespaces(node)
      namespaces.each do |prefix, href|
        node.add_namespace_definition(prefix.to_s, href)
      end
    end
  end
end
