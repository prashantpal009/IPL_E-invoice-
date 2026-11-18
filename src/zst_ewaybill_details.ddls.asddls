@EndUserText.label: 'Parameter for Irn Create'
define abstract entity ZST_EWAYBILL_DETAILS
{
  BillingDocument    : abap.char(10);
  TransporterId      : abap.char(20);
  TransporterGstin   : abap.char(15);
  TransporterName    : abap.char(100);
  TransportDocNumber : abap.char(50);
  TransportDocDate   : abap.dats;
  ModeOfTransport    : abap.char(20);
  VehicleType        : abap.char(20);
  DistanceKm         : abap.dec(10,2);
  VehicleNumber      : abap.char(20);
}
