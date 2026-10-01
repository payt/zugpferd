require "test_helper"

# BT-12, BT-18, BT-19, BG-14, BG-15 (with BT-70/BT-71) and BG-24
class DocumentDetailsTest < Minitest::Test
  UBL = <<~XML.freeze
    <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
             xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
             xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
      <cbc:ID>INV-3</cbc:ID>
      <cbc:IssueDate>2026-10-01</cbc:IssueDate>
      <cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>
      <cbc:DocumentCurrencyCode>EUR</cbc:DocumentCurrencyCode>
      <cbc:AccountingCost>4217:2323</cbc:AccountingCost>
      <cac:InvoicePeriod>
        <cbc:StartDate>2026-09-01</cbc:StartDate>
        <cbc:EndDate>2026-09-30</cbc:EndDate>
      </cac:InvoicePeriod>
      <cac:ContractDocumentReference><cbc:ID>CON-7</cbc:ID></cac:ContractDocumentReference>
      <cac:AdditionalDocumentReference>
        <cbc:ID schemeID="ABT">DR35141</cbc:ID>
        <cbc:DocumentTypeCode>130</cbc:DocumentTypeCode>
      </cac:AdditionalDocumentReference>
      <cac:AdditionalDocumentReference>
        <cbc:ID>timesheet</cbc:ID>
        <cbc:DocumentDescription>Timesheet</cbc:DocumentDescription>
        <cac:Attachment>
          <cbc:EmbeddedDocumentBinaryObject mimeCode="application/pdf" filename="timesheet.pdf">aGVsbG8=</cbc:EmbeddedDocumentBinaryObject>
          <cac:ExternalReference><cbc:URI>https://example.com/timesheet</cbc:URI></cac:ExternalReference>
        </cac:Attachment>
      </cac:AdditionalDocumentReference>
      <cac:Delivery>
        <cbc:ActualDeliveryDate>2026-09-30</cbc:ActualDeliveryDate>
        <cac:DeliveryLocation>
          <cbc:ID schemeID="0088">7300010000001</cbc:ID>
          <cac:Address>
            <cbc:StreetName>Lieferweg 2</cbc:StreetName>
            <cbc:AdditionalStreetName>Halle 5</cbc:AdditionalStreetName>
            <cbc:CityName>Berlin</cbc:CityName>
            <cbc:PostalZone>10115</cbc:PostalZone>
            <cbc:CountrySubentity>Berlin</cbc:CountrySubentity>
            <cac:AddressLine><cbc:Line>Tor 3</cbc:Line></cac:AddressLine>
            <cac:Country><cbc:IdentificationCode>DE</cbc:IdentificationCode></cac:Country>
          </cac:Address>
        </cac:DeliveryLocation>
        <cac:DeliveryParty><cac:PartyName><cbc:Name>Lager Berlin</cbc:Name></cac:PartyName></cac:DeliveryParty>
      </cac:Delivery>
      <cac:TaxTotal>
        <cbc:TaxAmount currencyID="EUR">19.00</cbc:TaxAmount>
      </cac:TaxTotal>
      <cac:LegalMonetaryTotal>
        <cbc:LineExtensionAmount currencyID="EUR">100.00</cbc:LineExtensionAmount>
        <cbc:TaxExclusiveAmount currencyID="EUR">100.00</cbc:TaxExclusiveAmount>
        <cbc:TaxInclusiveAmount currencyID="EUR">119.00</cbc:TaxInclusiveAmount>
        <cbc:PayableAmount currencyID="EUR">119.00</cbc:PayableAmount>
      </cac:LegalMonetaryTotal>
    </Invoice>
  XML

  CII_NS = Zugpferd::CII::Mapping::NS

  def test_ubl_reader_reads_the_details
    assert_details Zugpferd::UBL::Reader.new.read(UBL)
  end

  def test_cii_writer_writes_the_details
    cii = Nokogiri::XML(Zugpferd::CII::Writer.new.write(Zugpferd::UBL::Reader.new.read(UBL)))
    agreement = cii.at_xpath("//ram:ApplicableHeaderTradeAgreement", CII_NS)
    settlement = cii.at_xpath("//ram:ApplicableHeaderTradeSettlement", CII_NS)
    ship_to = cii.at_xpath("//ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty", CII_NS)
    documents = agreement.xpath("ram:AdditionalReferencedDocument", CII_NS)

    assert_equal "CON-7", agreement.at_xpath("ram:ContractReferencedDocument/ram:IssuerAssignedID", CII_NS).text
    assert_equal %w[130 916], documents.map { |d| d.at_xpath("ram:TypeCode", CII_NS).text }
    assert_equal "ABT", documents.first.at_xpath("ram:ReferenceTypeCode", CII_NS).text
    assert_equal "timesheet.pdf", documents.last.at_xpath("ram:AttachmentBinaryObject", CII_NS)["filename"]
    assert_equal "4217:2323", settlement.at_xpath("ram:ReceivableSpecifiedTradeAccountingAccount/ram:ID", CII_NS).text
    assert_equal "20260901", settlement.at_xpath("ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString", CII_NS).text
    assert_equal "0088", ship_to.at_xpath("ram:GlobalID", CII_NS)["schemeID"]
    assert_equal "Tor 3", ship_to.at_xpath("ram:PostalTradeAddress/ram:LineThree", CII_NS).text
  end

  def test_details_survive_a_cii_and_ubl_roundtrip
    cii = Zugpferd::CII::Writer.new.write(Zugpferd::UBL::Reader.new.read(UBL))
    ubl = Zugpferd::UBL::Writer.new.write(Zugpferd::CII::Reader.new.read(cii))

    assert_details Zugpferd::UBL::Reader.new.read(ubl)
  end

  private

  def assert_details(invoice)
    assert_equal "CON-7", invoice.contract_reference
    assert_equal "4217:2323", invoice.buyer_accounting_reference
    assert_equal [Date.new(2026, 9, 1), Date.new(2026, 9, 30)],
      [invoice.invoice_period_start_date, invoice.invoice_period_end_date]

    object, timesheet = invoice.additional_documents
    assert object.invoiced_object?
    assert_equal %w[DR35141 ABT], [object.id, object.scheme_id]
    assert_equal ["timesheet", "Timesheet", "aGVsbG8=", "application/pdf", "timesheet.pdf", "https://example.com/timesheet"],
      [timesheet.id, timesheet.description, timesheet.attachment, timesheet.mime_code, timesheet.filename, timesheet.uri]
    assert_nil timesheet.type_code

    location = invoice.delivery_location
    assert_equal ["Lager Berlin", "7300010000001", "0088"], [location.party_name, location.id, location.scheme_id]
    address = location.address
    assert_equal ["Lieferweg 2", "Halle 5", "Tor 3", "Berlin", "10115", "Berlin", "DE"],
      [address.street_name, address.additional_street_name, address.address_line, address.city_name,
       address.postal_zone, address.country_subdivision, address.country_code]
  end
end
