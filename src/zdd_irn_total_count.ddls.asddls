@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Total IRN KPI'

define view entity ZDD_IRN_TOTAL_COUNT
  as select from ZDD_IRN
{
  key cast(
      'TOTAL' as abap.char(10)
  )     as KpiId,

      count(
          distinct BillingDocument
      ) as Total 
}
