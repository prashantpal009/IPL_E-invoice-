@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCUSTOMER_VH
  as select from I_Customer
{
  key Customer,
      CustomerName 
}
