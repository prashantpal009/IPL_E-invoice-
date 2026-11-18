@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant GST Details'
define root view entity ZI_PlantGstDetails
  as select from zplant_gst
{
  key plant                 as Plant,
  key gstin                 as Gstin,
      tax_region            as TaxRegion,
      description           as Description,
      user_id               as UserId,
      password              as Password,
      mobile_no             as MobileNo,
      email                 as Email,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
