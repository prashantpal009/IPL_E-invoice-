@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZPLANT_VH
  as select from I_Plant
{
  key Plant,
      PlantName 
}
