module Zugpferd
  module Model
    # Postal address (BG-5 / BG-8).
    class PostalAddress
      # @return [String, nil] BT-35/BT-50/BT-75 Street name
      # @return [String, nil] BT-36/BT-51/BT-76 Additional street name
      # @return [String, nil] BT-162/BT-163/BT-165 Address line 3
      # @return [String, nil] BT-39/BT-54/BT-79 Country subdivision
      # @return [String, nil] BT-37/BT-52 City name
      # @return [String, nil] BT-38/BT-53 Postal zone
      # @return [String] BT-40/BT-55 Country code
      attr_accessor :street_name, :additional_street_name, :address_line,
                    :city_name, :postal_zone, :country_subdivision, :country_code

      # @param country_code [String] BT-40/BT-55 Country code (ISO 3166-1 alpha-2)
      # @param rest [Hash] additional attributes set via accessors
      def initialize(country_code:, **rest)
        @country_code = country_code
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
