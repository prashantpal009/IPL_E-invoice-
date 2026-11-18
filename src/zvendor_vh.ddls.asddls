@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZVENDOR_VH as select from I_Supplier
{
    key Supplier,
    SupplierName,
    SupplierFullName
    
}
