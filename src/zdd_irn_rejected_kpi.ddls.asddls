@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IRN KPI Count'

define view entity ZDD_IRN_REJECTED_KPI
  as select from zdt_einvoice
{
  key cast( 'REJECTED' as abap.char( 10 ) ) as KpiId,

      count( distinct billingdocument )     as rejected 
}
where
  irnstatus = 'Rejected'
