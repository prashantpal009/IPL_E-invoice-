@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Billing'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZBILLING_VH as select from I_BillingDocument as a
{
    key a.DocumentReferenceID ,
    key a.BillingDocument,
    a.BillingDocumentType 
}
