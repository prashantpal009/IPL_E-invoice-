@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data Defin of Einvoice EwayBill Logs'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZDD_EINV_EWB_LOG
  as select from zdt_einv_ewb_log
{
  key log_id           as LogId,
      billingdocument  as Billingdocument,
      process_type     as ProcessType,
      irn              as Irn,
      ewb_no           as EwbNo,
      request_payload  as RequestPayload,
      response_payload as ResponsePayload,
      http_status      as HttpStatus,
      status           as Status,
      error_message    as ErrorMessage,
      @Semantics.systemDateTime.createdAt: true
      created_at       as CreatedAt,
      @Semantics.user.createdBy: true
      created_by       as CreatedBy
      
}
