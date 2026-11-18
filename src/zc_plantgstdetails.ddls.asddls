@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@EndUserText.label: 'Plant GST Details - Projection'
define root view entity ZC_PlantGstDetails
  provider contract transactional_query
  as projection on ZI_PlantGstDetails
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Plant'
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
  key Plant,

      @Search.defaultSearchElement: true
      @EndUserText.label: 'GSTIN'
  key Gstin,

      @EndUserText.label: 'Tax Region'
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_RegionVH', element: 'Region' },
                                           additionalBinding: [{ localConstant: 'IN',
                                                                 element: 'Country',
                                                                 usage: #FILTER }] }]
      TaxRegion,

      @Search.defaultSearchElement: true
      @EndUserText.label: 'Description'
      Description,

      @EndUserText.label: 'User ID'
      UserId,

      @EndUserText.label: 'Password'
      Password,

      @EndUserText.label: 'Mobile No.'
      MobileNo,

      @EndUserText.label: 'Email'
      Email,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
