module Zugpferd
  module Model
    # Additional supporting document (BG-24), the invoiced object identifier (BT-18) when
    # +type_code+ is "130", or the tender or lot reference (BT-17) when +type_code+ is "50".
    class AdditionalDocument
      INVOICED_OBJECT_TYPE_CODE = "130".freeze
      TENDER_TYPE_CODE = "50".freeze

      # @return [String] BT-122 Supporting document reference (BT-18 for type code 130)
      # @return [String, nil] BT-18-1 Scheme identifier of the invoiced object identifier
      # @return [String, nil] Document type code: "130" for BT-18, "50" for BT-17, nil for BG-24
      # @return [String, nil] BT-123 Supporting document description
      # @return [String, nil] BT-124 External document location
      # @return [String, nil] BT-125 Attached document, Base64 encoded
      # @return [String, nil] BT-125-1 Attached document mime code
      # @return [String, nil] BT-125-2 Attached document filename
      attr_accessor :id, :scheme_id, :type_code, :description, :uri,
                    :attachment, :mime_code, :filename

      # @param id [String] BT-122 Supporting document reference
      # @param rest [Hash] additional attributes set via accessors
      def initialize(id:, **rest)
        @id = id
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end

      def invoiced_object?
        type_code == INVOICED_OBJECT_TYPE_CODE
      end

      def tender?
        type_code == TENDER_TYPE_CODE
      end
    end
  end
end
