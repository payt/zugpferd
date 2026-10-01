require "test_helper"

# BT-13 purchase order reference and BT-25/BT-26 preceding invoice reference
class DocumentReferencesTest < Minitest::Test
  UBL = <<~XML.freeze
    <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
             xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
             xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
      <cbc:ID>INV-2</cbc:ID>
      <cbc:IssueDate>2026-10-01</cbc:IssueDate>
      <cbc:InvoiceTypeCode>384</cbc:InvoiceTypeCode>
      <cbc:DocumentCurrencyCode>EUR</cbc:DocumentCurrencyCode>
      <cac:OrderReference><cbc:ID>PO-42</cbc:ID></cac:OrderReference>
      <cac:BillingReference>
        <cac:InvoiceDocumentReference>
          <cbc:ID>INV-1</cbc:ID>
          <cbc:IssueDate>2026-09-01</cbc:IssueDate>
        </cac:InvoiceDocumentReference>
      </cac:BillingReference>
      <cac:TaxTotal>
        <cbc:TaxAmount currencyID="EUR">21.00</cbc:TaxAmount>
      </cac:TaxTotal>
      <cac:LegalMonetaryTotal>
        <cbc:LineExtensionAmount currencyID="EUR">100.00</cbc:LineExtensionAmount>
        <cbc:TaxExclusiveAmount currencyID="EUR">100.00</cbc:TaxExclusiveAmount>
        <cbc:TaxInclusiveAmount currencyID="EUR">121.00</cbc:TaxInclusiveAmount>
        <cbc:PayableAmount currencyID="EUR">121.00</cbc:PayableAmount>
      </cac:LegalMonetaryTotal>
    </Invoice>
  XML

  CII_NS = Zugpferd::CII::Mapping::NS

  def test_ubl_reader_reads_the_references
    invoice = Zugpferd::UBL::Reader.new.read(UBL)

    assert_equal "PO-42", invoice.purchase_order_reference
    assert_equal "INV-1", invoice.preceding_invoice_reference
    assert_equal Date.new(2026, 9, 1), invoice.preceding_invoice_issue_date
  end

  def test_cii_writer_writes_the_references
    cii = Nokogiri::XML(Zugpferd::CII::Writer.new.write(Zugpferd::UBL::Reader.new.read(UBL)))
    transaction = "//rsm:SupplyChainTradeTransaction"

    assert_equal "PO-42", cii.at_xpath(
      "#{transaction}/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID", CII_NS
    ).text
    reference = cii.at_xpath("#{transaction}/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument", CII_NS)
    assert_equal "INV-1", reference.at_xpath("ram:IssuerAssignedID", CII_NS).text
    assert_equal "20260901", reference.at_xpath("ram:FormattedIssueDateTime/qdt:DateTimeString", CII_NS).text
  end

  def test_references_survive_a_cii_and_ubl_roundtrip
    cii = Zugpferd::CII::Writer.new.write(Zugpferd::UBL::Reader.new.read(UBL))
    ubl = Zugpferd::UBL::Writer.new.write(Zugpferd::CII::Reader.new.read(cii))
    invoice = Zugpferd::UBL::Reader.new.read(ubl)

    assert_equal "PO-42", invoice.purchase_order_reference
    assert_equal "INV-1", invoice.preceding_invoice_reference
    assert_equal Date.new(2026, 9, 1), invoice.preceding_invoice_issue_date
  end
end
