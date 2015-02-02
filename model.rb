require 'qml'
require_relative 'example-config-parser'
require_relative 'config-parser'

module SDDMConfigurationEditor
  module Model
    def self.find_counterparts(array1, array2, key, &block)
      array1.each do |item1|
        found = array2.find do |item2|
          item2[key] == item1[key]
        end
        yield [item1, found]
      end
    end

    def self.create
      config_schema = ExampleConfigParser.new.parse(File.read('data/example.conf'))
      config_values = ConfigParser.new.parse(File.read('/etc/sddm.conf'))

      # Merge values into schema
      find_counterparts(config_values, config_schema, :section) do
        |(value_section, schema_section)|
        section_name = value_section[:section]
        if schema_section
          value_settings = value_section[:settings]
          schema_settings = schema_section[:settings]
          find_counterparts(value_settings, schema_settings, :key) do
            |value_setting, schema_setting|
            if schema_setting
              schema_setting[:value] = value_setting[:value]
            else
              warn "Unimplemented: setting [#{section_name}]/#{value_setting[:key]} does not exist in example config."
            end
          end
        else
          warn "Unimplemented: section [#{section_name}] does not exist in example config."
        end
      end

      # Replace the plain arrays of settings with ArrayModels
      config_schema.each do |section|
        settings = section[:settings]
        settings_model = QML::Data::ArrayModel.new(*settings.first.keys)
        settings_model.replace(settings)
        section[:settings] = settings_model
      end

      model = QML::Data::ArrayModel.new(:section, :settings)
      model.replace(config_schema)
      model
    end
  end
end

