@EndUserText.label: 'Data Defination for Einvoice'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZDD_i_billingdocumentitem
  as select from I_BillingDocumentItem
{
  key BillingDocument,
      Plant,
      ShipToParty
}
group by
  BillingDocument,
  Plant,
  ShipToParty
