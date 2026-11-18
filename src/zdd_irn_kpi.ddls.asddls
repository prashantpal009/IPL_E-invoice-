@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IRN KPI Count'

define view entity ZDD_IRN_KPI
  as select from zdt_einvoice
{
    key cast( 'TODAY' as abap.char( 10 ) ) as KpiId,


    count( distinct billingdocument )     as GeneratedToday
}
where created_date >= $session.system_date
