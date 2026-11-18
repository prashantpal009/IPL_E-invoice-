@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant GST Details - API (read only)'
define view entity ZA_PlantGstDetails
  as select from zplant_gst
{
  key plant           as Plant,
  key gstin           as Gstin,
      tax_region      as TaxRegion,
      description     as Description,
      user_id         as UserId,
      password        as Password,
      mobile_no       as MobileNo,
      email           as Email,
      last_changed_at as LastChangedAt
}
