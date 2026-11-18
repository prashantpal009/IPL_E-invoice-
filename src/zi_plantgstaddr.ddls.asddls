@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant GSTIN and Address for e-Invoice'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_PlantGstAddr
  as select from I_Plant as Plant
    left outer join I_Address_2 as Adr
      on  Adr.AddressID                 = Plant.AddressID
      and Adr.AddressPersonID           = ''
      and Adr.AddressRepresentationCode = ''
{
  key Plant.Plant,
      Plant.PlantName,
      Adr.PostalCode,
      Plant.AddressID,

      /* GSTIN only from custom table - no standard fallback */
//      Gst.gstin_no                                              as GSTIN,
//      substring( Gst.gstin_no, 1, 2 )                           as GSTStateCode,

      /* Legal / trade name */
//      case when Gst.legal_name is null or Gst.legal_name = ''
//           then cast( Plant.PlantName  as abap.char(100) )
//           else cast( Gst.legal_name   as abap.char(100) )
//      end                                                       as LegalName,
//
//      case when Gst.trade_name is null or Gst.trade_name = ''
//           then cast( Plant.PlantName  as abap.char(100) )
//           else cast( Gst.trade_name   as abap.char(100) )
//      end                                                       as TradeName,

      /* Address line 1 */
//      case when Gst.address1 is null or Gst.address1 = ''
//           then cast( concat_with_space(
//                        concat_with_space( coalesce( Adr.HouseNumber, '' ),
//                                           coalesce( Adr.StreetName,  '' ), 1 ),
//                        coalesce( Adr.StreetPrefixName1, '' ), 1 ) as abap.char(100) )
//           else cast( Gst.address1 as abap.char(100) )
//      end                                                       as Address1,

      /* Address line 2 */
//      case when Gst.address1 is null or Gst.address1 = ''
//           then cast( concat_with_space( coalesce( Adr.StreetSuffixName1, '' ),
//                                         coalesce( Adr.DistrictName,      '' ), 1 )
//                      as abap.char(100) )
//           else cast( Gst.address2 as abap.char(100) )
//      end                                                       as Address2,

      /* City */
//      case when Gst.city is null or Gst.city = ''
//           then cast( Adr.CityName as abap.char(50) )
//           else cast( Gst.city     as abap.char(50) )
//      end                                                       as City,

      /* Pincode */
//      case when Gst.pincode is null or Gst.pincode = ''
//           then cast( Adr.PostalCode as abap.char(10) )
//           else cast( Gst.pincode    as abap.char(10) )
//      end                                                       as Pincode,

      Adr.Region,
      Adr.Country
//      Gst.phone                                                 as Phone,
//      Gst.email                                                 as Email,

      /* Debug helper: where the address came from */
//      case when Gst.address1 is null or Gst.address1 = ''
//           then 'P'      // P = standard plant address
//           else 'Z'      // Z = ZTEI_PLANT_GST
//      end                                                       as AddressSource
}
