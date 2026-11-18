@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data Defination for IRN'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZDD_IRN
  as select from    I_BillingDocument         as a
    left outer join ZDD_i_billingdocumentitem as c on a.BillingDocument = c.BillingDocument
    left outer join zdt_einvoice              as b on a.BillingDocument = b.billingdocument
{
      @UI.facet: [{
          id: '10',
          purpose: #STANDARD,
          position: 10,
          label: 'Item',
          type: #IDENTIFICATION_REFERENCE
      }]
      
      @UI.lineItem: [{ label: 'Invoice No.',position: 5 }]
      @UI.identification: [{ label: 'Invoice No.',position: 5 }]
      @Consumption.valueHelpDefinition: [
        {
            entity: {
                name: 'I_BillingDocument',
                element: 'BillingDocument'
            }
        }
      ]
  key a.BillingDocument,
           @UI.lineItem: [{ label: 'ODN Number', position: 10 }]
      @UI.identification: [{ label: 'ODN Number', position: 10 }]
      a.DocumentReferenceID as Odn,

      @UI.lineItem: [{ label: 'Billing Type', position: 15 }]
      @UI.identification: [{ label: 'Billing Type', position: 15 }]
      a.BillingDocumentType as BillingDocumentType,
      @UI.lineItem: [{ label: 'Plant',position: 20 },{
        type: #FOR_ACTION,
        dataAction: 'GenerateIRN',
        label: 'Generate IRN',
        position: 20
      }]
      @UI.identification: [{ label: 'Plant',position: 20 }]
      c.Plant               as Plant,
      
      @UI.lineItem: [{ label: 'Company Code',position: 30 },{
        type: #FOR_ACTION,
        dataAction: 'IrnPayload',
        label: 'Irn Payload',
        position: 30
      }]
      @UI.identification: [{ label: 'Company Code',position: 30 }]
      a.CompanyCode         as Companycode,
      @UI.lineItem: [{ label: 'Customer',position: 35 }]
      @UI.identification: [{ label: 'Customer',position: 35 }]
      c.ShipToParty         as Customer,

      @UI.lineItem: [{ label: 'Customer',position: 36 }]
      @UI.identification: [{ label: 'Customer',position: 36 }]
      a.BillingDocumentDate as PostingDate,

      @UI.lineItem: [{ label: 'Irn',position: 40 }]
      @UI.identification: [{ label: 'Irn',position: 40 }]
      b.irn                 as Irn,
      @UI.lineItem: [{ label: 'Ack Date', position: 50 }]
      @UI.identification: [{ label: 'Ack Date', position: 50 }]
      b.ackdate             as Ackdate,

      @UI.lineItem: [{ label: 'Ack No.', position: 60 }]
      @UI.identification: [{ label: 'Ack No.', position: 60 }]
      b.ackno               as Ackno,

      @UI.lineItem: [{ label: 'E-Way Bill No.', position: 70 }]
      @UI.identification: [{ label: 'E-Way Bill No.', position: 70 }]
      b.ewbno               as Ewbno,

      @UI.lineItem: [{ label: 'E-Way Bill Date', position: 80 }]
      @UI.identification: [{ label: 'E-Way Bill Date', position: 80 }]
      b.ewbdt               as Ewbdt,

      @UI.lineItem: [{ label: 'E-Way Bill Valid Till', position: 90 }]
      @UI.identification: [{ label: 'E-Way Bill Valid Till', position: 90 }]
      b.ewbvalidtill        as Ewbvalidtill,

      @UI.lineItem: [{ label: 'Signed QR Code', position: 100 }]
      @UI.identification: [{ label: 'Signed QR Code', position: 100 }]
      b.signedqrcode        as Signedqrcode,

      @UI.lineItem: [{ label: 'Signed Invoice', position: 110 }]
      @UI.identification: [{ label: 'Signed Invoice', position: 110 }]
      b.signedinvoice       as Signedinvoice,

      @UI.lineItem: [{ label: 'Qrcode', position: 112 }]
      @UI.identification: [{ label: 'Qrcode', position: 112 }]
      b.qrcode              as Qrcode,

      @UI.lineItem: [{ label: 'IRN Status', position: 120 }]
      @UI.identification: [{ label: 'IRN Status', position: 120 }]
      b.irnstatus           as Irnstatus,
      @UI.lineItem: [{ label: 'Eway Status', position: 123 }]
      @UI.identification: [{ label: 'Eway Status', position: 123 }]
      b.ewaybillstatus      as EwayBillStatus,

      @UI.lineItem: [{ label: 'Transporter ID', position: 130 }]
      @UI.identification: [{ label: 'Transporter ID', position: 130 }]
      b.transporterid       as TransporterId,

      @UI.lineItem: [{ label: 'Transporter GSTIN', position: 140 }]
      @UI.identification: [{ label: 'Transporter GSTIN', position: 140 }]
      b.transportergstin    as TransporterGstin,

      @UI.lineItem: [{ label: 'Transporter Name', position: 150 }]
      @UI.identification: [{ label: 'Transporter Name', position: 150 }]
      b.transportername     as TransporterName,

      @UI.lineItem: [{ label: 'Transport Document Number', position: 160 }]
      @UI.identification: [{ label: 'Transport Document Number', position: 160 }]
      b.transportdocnumber  as TransportDocNumber,

      @UI.lineItem: [{ label: 'Transport Document Date', position: 170 }]
      @UI.identification: [{ label: 'Transport Document Date', position: 170 }]
      b.transportdocdate    as TransportDocDate,

      @UI.lineItem: [{ label: 'Mode of Transport', position: 180 }]
      @UI.identification: [{ label: 'Mode of Transport', position: 180 }]
      b.modeoftransport     as ModeOfTransport,

      @UI.lineItem: [{ label: 'Vehicle Type', position: 190 }]
      @UI.identification: [{ label: 'Vehicle Type', position: 190 }]
      b.vehicletype         as VehicleType,

      @UI.lineItem: [{ label: 'Distance (KM)', position: 200 }]
      @UI.identification: [{ label: 'Distance (KM)', position: 200 }]
      b.distancekm          as DistanceKm,

      @UI.lineItem: [{ label: 'Vehicle Number', position: 210 }]
      @UI.identification: [{ label: 'Vehicle Number', position: 210 }]
      b.vehiclenumber       as VehicleNumber,

      @UI.lineItem: [{ label: 'Created At', position: 130 }]
      @UI.identification: [{ label: 'Created At', position: 130 }]
      b.created_at          as Createdat,
      @UI.lineItem: [{ label: 'Created By', position: 140 }]
      @UI.identification: [{ label: 'Created By', position: 140 }]
      b.created_by          as Createdby,
      @UI.lineItem: [{ label: 'Last Changed At', position: 150 }]
      @UI.identification: [{ label: 'Last Changed At', position: 150 }]
      b.last_changed_at     as Lastchangedat,
      @UI.lineItem: [{ label: 'Last Changed By', position: 160 }]
      @UI.identification: [{ label: 'Last Changed By', position: 160 }]
      b.last_changed_by     as Lastchangedby
}where
  a.BillingDocumentType <> 'S1'
