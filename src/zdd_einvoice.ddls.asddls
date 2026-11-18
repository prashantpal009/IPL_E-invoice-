@EndUserText.label: 'Data Defination for Einvoice'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZDD_EINVOICE
  as select from zdt_einvoice
{
  key billingdocument    as Billingdocument,
      plant              as Plant,
      companycode        as Companycode,
      irn                as Irn,
      ackdate            as Ackdate,
      ackno              as Ackno,
      ewbno              as Ewbno,
      ewbdt              as Ewbdt,
      ewbvalidtill       as Ewbvalidtill,
      signedqrcode       as Signedqrcode,
      signedinvoice      as Signedinvoice,
      qrcode             as Qrcode,
      irnstatus          as Irnstatus,
      ewaybillstatus     as EwayBillStatus,
      transporterid      as TransporterId,
      transportergstin   as TransporterGstin,
      transportername    as TransporterName,
      transportdocnumber as TransportDocNumber,
      transportdocdate   as TransportDocDate,
      modeoftransport    as ModeOfTransport,
      vehicletype        as VehicleType,
      distancekm         as DistanceKm,
      vehiclenumber      as VehicleNumber,
      @Semantics.systemDateTime.createdAt: true
      created_at         as Createdat,
      @Semantics.user.createdBy: true
      created_by         as Createdby,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at    as Lastchangedat,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by    as Lastchangedby,
      created_date       as Createddate
}
