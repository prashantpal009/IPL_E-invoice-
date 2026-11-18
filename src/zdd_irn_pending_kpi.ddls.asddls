@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pending IRN KPI'

define view entity ZDD_IRN_PENDING_KPI
  as select from ZDD_IRN_TOTAL_COUNT as a
    cross join ZDD_IRN_SUBMIT_KPI as b
    cross join ZDD_IRN_REJECTED_KPI as c
{
    key cast(
        'PENDING' as abap.char(10)
    ) as KpiId,
 
    a.Total - b.submitted - c.rejected as Pending
}
