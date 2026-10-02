module Zugpferd
  module Model
    # Deliver to information (BG-13 without the delivery date, which stays on the document).
    class DeliveryLocation
      # @return [String, nil] BT-70 Deliver to party name
      # @return [String, nil] BT-71 Deliver to location identifier
      # @return [String, nil] BT-71-1 Scheme identifier of the location identifier
      # @return [PostalAddress, nil] BG-15 Deliver to address
      attr_accessor :party_name, :id, :scheme_id, :address

      # @param rest [Hash] attributes set via accessors
      def initialize(**rest)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
