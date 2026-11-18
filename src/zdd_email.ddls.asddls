@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Address'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZDD_EMAIL as select from I_AddressEmailAddress_2 as a
{
    key AddressID,
    key AddressPersonID,
    key CommMediumSequenceNumber,
    EmailAddress,
    EmailAddressIsCurrentDefault,
    CommLineNotForUnsolicitedCntct,
    ValidityStartDate,
    ValidityEndDate,
    /* Associations */
    _AddressCommunicationRemark,
    _AddressCommunicationUsage,
    _AddressPersonName,
    _OrgNamePostalAddress
}
