@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IRN KPI Count'

define view entity ZDD_IRN_SUBMIT_KPI
  as select from zdt_einvoice
{
  key cast( 'GENERATED' as abap.char( 10 ) ) as KpiId,

      count( distinct billingdocument )      as submitted 
}
where
  irnstatus = 'Generated'
