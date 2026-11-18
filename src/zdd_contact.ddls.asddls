@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Address'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZDD_CONTACT
  as select from I_AddressPhoneNumber_2 as a
{
  key AddressID,
  key AddressPersonID,
  key CommMediumSequenceNumber,
      PhoneNumberCountry,
      PhNmbrIsCurrentOverallDefault,
      CommLineNotForUnsolicitedCntct,
      PhoneAreaCodeSubscriberNumber,
      PhoneExtensionNumber,
      InternationalPhoneNumber,
      PhoneIsSMSEnabled,
      PhoneNumberType,
      ValidityStartDate,
      ValidityEndDate,
      /* Associations */
      _AddressCommunicationRemark,
      _AddressCommunicationUsage,
      _PhoneNumberCountry,
      _PhoneNumberType
}
