CLASS lhc_zdd_irn DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR zdd_irn RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR zdd_irn RESULT result.
    METHODS generateirn FOR MODIFY
       keys FOR ACTION zdd_irn~generateirn RESULT result.
    METHODS irnpayload FOR MODIFY
       keys FOR ACTION zdd_irn~irnpayload RESULT result.
    METHODS cancelirn FOR MODIFY
       keys FOR ACTION zdd_irn~cancelirn RESULT result.
    METHODS cancelewaybill FOR MODIFY
       keys FOR ACTION zdd_irn~cancelewaybill RESULT result.

    METHODS cancelewaybillpayload FOR MODIFY
       keys FOR ACTION zdd_irn~cancelewaybillpayload RESULT result.

    METHODS cancelirnpayload FOR MODIFY
       keys FOR ACTION zdd_irn~cancelirnpayload RESULT result.

    METHODS ewaybillpayload FOR MODIFY
       keys FOR ACTION zdd_irn~ewaybillpayload RESULT result.

    METHODS generateewaybill FOR MODIFY
       keys FOR ACTION zdd_irn~generateewaybill RESULT result.
    METHODS updateewaybilldetails FOR MODIFY
       keys FOR ACTION zdd_irn~updateewaybilldetails RESULT result.

    METHODS get_odn
      IMPORTING iv_billingdocument TYPE i_billingdocument-billingdocument
      RETURNING VALUE(rv_odn)      TYPE string.
ENDCLASS.

CLASS lhc_zdd_irn IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
    result = VALUE #(
     %create = if_abap_behv=>auth-allowed
   ).
  ENDMETHOD.


  METHOD generateirn.

    DATA : lv_document TYPE i_billingdocument-billingdocument.
    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.
    DATA(lv_response) = zcl_generate_irn=>generate_irn( billingdocument = lv_document ).

    SELECT SINGLE FROM
    i_billingdocumentitem AS a
    FIELDS
    a~plant,
    a~companycode
    WHERE a~billingdocument = @lv_document
    INTO @DATA(lv_billing).

    DATA : lv_irn TYPE string.
    DATA : lv_qrcode TYPE string.
    DATA : lv_signedqrcode TYPE string.
    DATA : lv_ackdt TYPE string.
    DATA : lv_ackno TYPE string.
    DATA : lv_status TYPE string.

    TYPES: BEGIN OF ty_desc,
             ackno TYPE string,
             ackdt TYPE string,
             irn   TYPE string,
           END OF ty_desc,
           BEGIN OF ty_info,
             infcd TYPE string,
             desc  TYPE ty_desc,
           END OF ty_info,
           BEGIN OF ty_nic,
             status       TYPE string,
             ackno        TYPE string,
             ackdt        TYPE string,
             irn          TYPE string,
             signedqrcode TYPE string,
             infodtls     TYPE STANDARD TABLE OF ty_info WITH EMPTY KEY,
           END OF ty_nic.

    DATA ls_nic TYPE ty_nic.

    /ui2/cl_json=>deserialize( EXPORTING json = lv_response
                               CHANGING  data = ls_nic ).

    IF ls_nic-irn IS NOT INITIAL.

      lv_status       = 'SUCCESS'.
      lv_irn          = ls_nic-irn.
      lv_ackno        = ls_nic-ackno.
      lv_ackdt        = ls_nic-ackdt.
      lv_signedqrcode = ls_nic-signedqrcode.
      lv_qrcode       = ls_nic-signedqrcode.

    ELSE.

      READ TABLE ls_nic-infodtls INTO DATA(ls_info) WITH KEY infcd = 'DUPIRN'.
      IF sy-subrc = 0 AND ls_info-desc-irn IS NOT INITIAL.
        lv_status = 'SUCCESS'.
        lv_irn    = ls_info-desc-irn.
        lv_ackno  = ls_info-desc-ackno.
        lv_ackdt  = ls_info-desc-ackdt.
      ELSE.
        lv_status = 'FAILURE'.
      ENDIF.

    ENDIF.

    SELECT SINGLE FROM zdt_einvoice AS a
      FIELDS a~irn
      WHERE a~billingdocument = @lv_document
      INTO @DATA(lv_current_document).

    SELECT SINGLE FROM zdt_einvoice AS a
       FIELDS a~billingdocument
       WHERE a~billingdocument = @lv_document
       INTO @DATA(lv_current_document2).


    IF lv_status = 'SUCCESS'.

      IF lv_current_document2 IS INITIAL.
        MODIFY ENTITIES OF zdd_einvoice
          ENTITY zdd_einvoice
          CREATE FIELDS (
            billingdocument
            companycode
            plant
            irnstatus
            ackdate
            ackno
            signedqrcode
            qrcode
            irn
            createddate
          )
          WITH VALUE #(
            (
              %cid            = 'IRN_CREATE_001'
              billingdocument = lv_document
              companycode     = lv_billing-companycode
              plant           = lv_billing-plant
              irnstatus       = 'Generated'
              ackdate         = lv_ackdt
              ackno           = lv_ackno
              signedqrcode    = lv_signedqrcode
              qrcode          = lv_qrcode
              irn             = lv_irn
              createddate     = sy-datum
            )
          )
          MAPPED DATA(mapped_log)
          FAILED DATA(failed_log)
          REPORTED DATA(reported_log).
      ELSE.
        MODIFY ENTITIES OF zdd_einvoice
          ENTITY zdd_einvoice
          UPDATE FIELDS (
            billingdocument
            companycode
            plant
            irnstatus
            ackdate
            ackno
            signedqrcode
            qrcode
            irn
            createddate
          )
          WITH VALUE #(
            (
              billingdocument = lv_document
              companycode     = lv_billing-companycode
              plant           = lv_billing-plant
              irnstatus       = 'Generated'
              ackdate         = lv_ackdt
              ackno           = lv_ackno
              signedqrcode    = lv_signedqrcode
              qrcode          = lv_qrcode
              irn             = lv_irn
              createddate     = sy-datum
            )
          )
          MAPPED DATA(mapped_log_up)
          FAILED DATA(failed_log_up)
          REPORTED DATA(reported_log_up).
      ENDIF.

      MODIFY ENTITIES OF zdd_einv_ewb_log
        ENTITY zdd_einv_ewb_log
        CREATE FIELDS (
          billingdocument
          processtype
          status
          irn
          httpstatus
          requestpayload
          responsepayload
        )
        WITH VALUE #(
          (
            %cid            = 'IRN_LOG_001'
            billingdocument = lv_document
            processtype     = 'IRN'
            status          = 'Generated'
            irn             = lv_irn
            httpstatus      = '200'
            requestpayload  = zcl_payload_irn=>get_payload(
                                billingdocument = lv_document
                              )
            responsepayload = lv_response
          )
        )
        MAPPED DATA(mapped_logtable)
        FAILED DATA(failed_logtable)
        REPORTED DATA(reported_logtable).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '001'
          severity = if_abap_behv_message=>severity-success
          v1       = lv_irn
        )
      ) TO reported-zdd_irn.

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %param = VALUE #(
          json_payload = |Irn Generated Successfully : - { lv_irn }|
        )
      ) TO result.
      RETURN.


    ELSEIF lv_status = 'FAILURE'.

      IF lv_current_document2 IS INITIAL.

        MODIFY ENTITIES OF zdd_einvoice
          ENTITY zdd_einvoice
          CREATE FIELDS (
            billingdocument
            companycode
            plant
            irnstatus
            createddate
          )
          WITH VALUE #(
            (
              %cid            = 'IRN_CREATE_001'
              billingdocument = lv_document
              companycode     = lv_billing-companycode
              plant           = lv_billing-plant
              irnstatus       = 'Rejected'
              createddate     = sy-datum
            )
          )
          MAPPED DATA(mapped_log_f)
          FAILED DATA(failed_log_f)
          REPORTED DATA(reported_f).

      ELSE.
        MODIFY ENTITIES OF zdd_einvoice
        ENTITY zdd_einvoice
        UPDATE FIELDS (
          billingdocument
          companycode
          plant
          irnstatus
          createddate
        )
        WITH VALUE #(
          (
            billingdocument = lv_document
            companycode     = lv_billing-companycode
            plant           = lv_billing-plant
            irnstatus       = 'Rejected'
            createddate     = sy-datum
          )
        )
        MAPPED DATA(mapped_log_f2)
        FAILED DATA(failed_log_f2)
        REPORTED DATA(reported_f2).

      ENDIF.

      MODIFY ENTITIES OF zdd_einv_ewb_log
          ENTITY zdd_einv_ewb_log
          CREATE FIELDS (
            billingdocument
            processtype
            status
            httpstatus
            requestpayload
            responsepayload
          )
          WITH VALUE #(
            (
              %cid            = 'IRN_LOG_001'
              billingdocument = lv_document
              processtype     = 'IRN'
              status          = 'Rejected'
              httpstatus      = '400'
              requestpayload  = zcl_payload_irn=>get_payload(
                                  billingdocument = lv_document
                                )
              responsepayload = lv_response
            )
          )
          MAPPED DATA(mapped_logtable_f)
          FAILED DATA(failed_logtable_f)
          REPORTED DATA(reported_logtable_f).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '003'
          severity = if_abap_behv_message=>severity-error
          v1       = get_odn( lv_document )                       " ODN
        )
      ) TO reported-zdd_irn.

      APPEND VALUE #(
                %cid = keys[ 1 ]-%cid
                %param = VALUE #(
                  json_payload = |{ lv_response }|
                )
              ) TO result.
      RETURN.

    ELSE.

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '002'
          severity = if_abap_behv_message=>severity-error
          v1       = |Unknown IRN status: { lv_status }|
        )
      ) TO reported-zdd_irn.


      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
      ) TO failed-zdd_irn.

    ENDIF.

    APPEND VALUE #(
      %cid = keys[ 1 ]-%cid
      %msg = new_message(
        id       = 'ZIRN'
        number   = '002'
        severity = if_abap_behv_message=>severity-error
        v1       = |IRN already exists for ODN { get_odn( lv_document ) }|   " ODN
      )
    ) TO reported-zdd_irn.


    APPEND VALUE #(
      %cid = keys[ 1 ]-%cid
    ) TO failed-zdd_irn.

  ENDMETHOD.
  METHOD irnpayload.
    DATA : lv_document TYPE i_billingdocument-billingdocument.
    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.
    DATA(lv_response) = zcl_payload_irn=>get_payload( billingdocument = lv_document ).

    DATA : ls_data TYPE zst_irn_payload_res.
    ls_data = VALUE #(
                json_payload = lv_response
    ).


    result = VALUE #(
     (
       %cid = keys[ 1 ]-%cid
       %param = ls_data
     )
   ).
  ENDMETHOD.

  METHOD cancelirn.

    DATA : lv_document TYPE i_billingdocument-billingdocument.
    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.

    DATA(lv_request) = zccl_payload_cancel_irn=>get_payload( billingdocument = lv_document ).

    DATA(lv_response) = zcl_cancel_irn=>cancel_irn( billingdocument = lv_document ).

    TYPES: BEGIN OF ty_cancel,
             irn        TYPE string,
             canceldate TYPE string,
           END OF ty_cancel.

    DATA ls_cancel TYPE ty_cancel.

    IF lv_response IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_response
                                 CHANGING  data = ls_cancel ).
    ENDIF.

    IF ls_cancel-irn IS NOT INITIAL AND ls_cancel-canceldate IS NOT INITIAL.

      MODIFY ENTITIES OF zdd_einvoice
        ENTITY zdd_einvoice
        UPDATE FIELDS ( irnstatus )
        WITH VALUE #(
          (
            billingdocument = lv_document
            irnstatus       = 'Cancelled'
          )
        )
        MAPPED DATA(mapped_cnl)
        FAILED DATA(failed_cnl)
        REPORTED DATA(reported_cnl).

      MODIFY ENTITIES OF zdd_einv_ewb_log
        ENTITY zdd_einv_ewb_log
        CREATE FIELDS (
          billingdocument
          processtype
          status
          irn
          httpstatus
          requestpayload
          responsepayload
        )
        WITH VALUE #(
          (
            %cid            = 'CNL_LOG_001'
            billingdocument = lv_document
            processtype     = 'CANCEL IRN'
            status          = 'Cancelled'
            irn             = ls_cancel-irn
            httpstatus      = '200'
            requestpayload  = lv_request
            responsepayload = lv_response
          )
        )
        MAPPED DATA(mapped_log_s)
        FAILED DATA(failed_log_s)
        REPORTED DATA(reported_log_s).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '001'
          severity = if_abap_behv_message=>severity-success
          v1       = |IRN cancelled on { ls_cancel-canceldate }|
        )
      ) TO reported-zdd_irn.

      APPEND VALUE #(
        %cid   = keys[ 1 ]-%cid
        %param = VALUE #(
          json_payload = |IRN Cancelled Successfully : - { ls_cancel-irn } on { ls_cancel-canceldate }|
        )
      ) TO result.
      RETURN.

    ELSE.

      MODIFY ENTITIES OF zdd_einv_ewb_log
        ENTITY zdd_einv_ewb_log
        CREATE FIELDS (
          billingdocument
          processtype
          status
          httpstatus
          requestpayload
          responsepayload
        )
        WITH VALUE #(
          (
            %cid            = 'CNL_LOG_001'
            billingdocument = lv_document
            processtype     = 'CANCEL IRN'
            status          = 'Rejected'
            httpstatus      = '400'
            requestpayload  = lv_request
            responsepayload = COND #( WHEN lv_response IS INITIAL
                                      THEN 'No response from CPI'
                                      ELSE lv_response )
          )
        )
        MAPPED DATA(mapped_log_f)
        FAILED DATA(failed_log_f)
        REPORTED DATA(reported_log_f).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '001'
          severity = if_abap_behv_message=>severity-error
          v1       = 'IRN cancellation failed'
        )
      ) TO reported-zdd_irn.

      APPEND VALUE #(
        %cid   = keys[ 1 ]-%cid
        %param = VALUE #(
          json_payload = COND #( WHEN lv_response IS INITIAL
                                 THEN 'IRN cancellation failed - no response'
                                 ELSE lv_response )
        )
      ) TO result.
      RETURN.

    ENDIF.

  ENDMETHOD.

  METHOD cancelewaybill.

    TYPES : BEGIN OF ty_cnl_ewb,
              ewaybillno TYPE string,
              canceldate TYPE string,
            END OF ty_cnl_ewb.

    DATA : lv_document TYPE i_billingdocument-billingdocument,
           ls_cnl      TYPE ty_cnl_ewb,
           lv_errtext  TYPE string,
           lv_ok       TYPE abap_bool.

    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.

    SELECT SINGLE FROM zdt_einvoice
      FIELDS ewbno
      WHERE billingdocument = @lv_document
      INTO @DATA(lv_ewbno).

    DATA(lv_request)  = zcl_payload_cancel_eway=>get_payload( billingdocument = lv_document ).
    DATA(lv_response) = zcl_cancel_ewaybill=>cancel_irn( billingdocument = lv_document ).

    IF lv_response IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_response
                                 CHANGING  data = ls_cnl ).
    ENDIF.

    lv_ok = xsdbool( ls_cnl-ewaybillno IS NOT INITIAL AND ls_cnl-canceldate IS NOT INITIAL ).

    IF ls_cnl-ewaybillno IS NOT INITIAL.
      lv_ewbno = ls_cnl-ewaybillno.
    ENDIF.

    IF lv_ok = abap_true.

      MODIFY ENTITIES OF zdd_einvoice
        ENTITY zdd_einvoice
        UPDATE FIELDS ( ewaybillstatus )
        WITH VALUE #(
          (
            billingdocument = lv_document
            ewaybillstatus  = 'Cancelled'
          )
        )
        MAPPED DATA(mapped_cnl)
        FAILED DATA(failed_cnl)
        REPORTED DATA(reported_cnl).

      MODIFY ENTITIES OF zdd_einv_ewb_log
        ENTITY zdd_einv_ewb_log
        CREATE FIELDS (
          billingdocument
          processtype
          status
          ewbno
          httpstatus
          requestpayload
          responsepayload
        )
        WITH VALUE #(
          (
            %cid            = 'CNL_EWB_LOG_001'
            billingdocument = lv_document
            processtype     = 'CANCEL EWAY'
            status          = 'Cancelled'
            ewbno           = lv_ewbno
            httpstatus      = '200'
            requestpayload  = lv_request
            responsepayload = lv_response
          )
        )
        MAPPED DATA(mapped_log_s)
        FAILED DATA(failed_log_s)
        REPORTED DATA(reported_log_s).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '001'
          severity = if_abap_behv_message=>severity-success
          v1       = |E-Way Bill { lv_ewbno } cancelled|
        )
      ) TO reported-zdd_irn.

      APPEND VALUE #(
        %cid   = keys[ 1 ]-%cid
        %param = VALUE #(
          json_payload = |E-Way Bill Cancelled Successfully : - { lv_ewbno } on { ls_cnl-canceldate }|
        )
      ) TO result.
      RETURN.

    ELSE.

      lv_errtext = zcl_ewb_error=>get_error_text( lv_response ).

      MODIFY ENTITIES OF zdd_einv_ewb_log
        ENTITY zdd_einv_ewb_log
        CREATE FIELDS (
          billingdocument
          processtype
          status
          ewbno
          httpstatus
          requestpayload
          responsepayload
        )
        WITH VALUE #(
          (
            %cid            = 'CNL_EWB_LOG_002'
            billingdocument = lv_document
            processtype     = 'CANCEL EWAY'
            status          = 'Rejected'
            ewbno           = lv_ewbno
            httpstatus      = '400'
            requestpayload  = lv_request
            responsepayload = COND #( WHEN lv_response IS INITIAL
                                      THEN 'No response from CPI'
                                      ELSE |{ lv_errtext } | && lv_response )
          )
        )
        MAPPED DATA(mapped_log_f)
        FAILED DATA(failed_log_f)
        REPORTED DATA(reported_log_f).

      DATA(lv_first) = COND string( WHEN lv_errtext CS |\n|
                            THEN substring_before( val = lv_errtext sub = |\n| )
                            ELSE lv_errtext ).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '003'
          severity = if_abap_behv_message=>severity-error
          v1       = get_odn( lv_document )                       " ODN
          v2       = substring( val = lv_first
                                len = nmin( val1 = 50 val2 = strlen( lv_first ) ) )
        )
      ) TO reported-zdd_irn.

*      APPEND VALUE #(
*        %cid = keys[ 1 ]-%cid
*        %msg = new_message(
*          id       = 'ZIRN'
*          number   = '003'
*          severity = if_abap_behv_message=>severity-error
*          v1       = lv_document
*          v2       = substring( val = lv_errtext
*                                len = nmin( val1 = 50 val2 = strlen( lv_errtext ) ) )
*        )
*      ) TO reported-zdd_irn.

      APPEND VALUE #(
        %cid   = keys[ 1 ]-%cid
        %param = VALUE #( json_payload = lv_errtext )
      ) TO result.
      RETURN.

    ENDIF.

  ENDMETHOD.

  METHOD cancelewaybillpayload.

    DATA : lv_document TYPE i_billingdocument-billingdocument.

    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.

    DATA(lv_response) = zcl_payload_cancel_eway=>get_payload( billingdocument = lv_document ).

    APPEND VALUE #( %cid   = keys[ 1 ]-%cid
                    %param = VALUE #( json_payload = lv_response ) ) TO result.

  ENDMETHOD.

  METHOD cancelirnpayload.
    DATA : lv_document TYPE i_billingdocument-billingdocument.
    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.
    DATA(lv_response) = zccl_payload_cancel_irn=>get_payload( billingdocument = lv_document ).

    DATA : ls_data TYPE zst_irn_payload_res.
    ls_data = VALUE #(
                json_payload = lv_response
    ).


    result = VALUE #(
     (
       %cid = keys[ 1 ]-%cid
       %param = ls_data
     )
   ).
  ENDMETHOD.

  METHOD ewaybillpayload.

    DATA : lv_document TYPE i_billingdocument-billingdocument.

    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.

    DATA(lv_response) = zcl_ewaybill_payload=>generate_payload( billingdocument = lv_document ).

    APPEND VALUE #( %cid   = keys[ 1 ]-%cid
                    %param = VALUE #( json_payload = lv_response ) ) TO result.

  ENDMETHOD.


  METHOD generateewaybill.

    DATA : lv_document TYPE i_billingdocument-billingdocument.
    lv_document = |{ keys[ 1 ]-%param-billingdocument ALPHA = IN }|.

    DATA(lv_request)  = zcl_ewaybill_payload=>generate_payload( billingdocument = lv_document ).
    DATA(lv_response) = zcl_ewaybill_generate=>generate_ewaybill( billingdocument = lv_document ).

    SELECT SINGLE FROM
    i_billingdocumentitem AS a
    FIELDS
    a~plant,
    a~companycode
    WHERE a~billingdocument = @lv_document
    INTO @DATA(lv_billing).

    DATA : lv_ewaybill     TYPE string.
    DATA : lv_ewbdt        TYPE string.
    DATA : lv_ewbvalidtill TYPE string.
    DATA : lv_status       TYPE string.
    DATA : lv_errtext      TYPE string.

    TYPES: BEGIN OF ty_ewb,
             ewaybillno   TYPE string,
             ewaybilldate TYPE string,
             validupto    TYPE string,
             ewbno        TYPE string,
             ewbdt        TYPE string,
             ewbvalidtill TYPE string,
           END OF ty_ewb.

    DATA ls_ewb TYPE ty_ewb.

    IF lv_response IS NOT INITIAL.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_response
                                 CHANGING  data = ls_ewb ).
    ENDIF.

    lv_ewaybill     = COND #( WHEN ls_ewb-ewaybillno   IS NOT INITIAL THEN ls_ewb-ewaybillno   ELSE ls_ewb-ewbno ).
    lv_ewbdt        = COND #( WHEN ls_ewb-ewaybilldate IS NOT INITIAL THEN ls_ewb-ewaybilldate ELSE ls_ewb-ewbdt ).
    lv_ewbvalidtill = COND #( WHEN ls_ewb-validupto    IS NOT INITIAL THEN ls_ewb-validupto    ELSE ls_ewb-ewbvalidtill ).

    lv_status = COND #( WHEN lv_ewaybill IS NOT INITIAL AND lv_ewaybill <> '0'
                        THEN 'SUCCESS' ELSE 'FAILURE' ).

    SELECT SINGLE FROM zdt_einvoice AS a
       FIELDS a~billingdocument
       WHERE a~billingdocument = @lv_document
       INTO @DATA(lv_current_document2).


    IF lv_status = 'SUCCESS'.

      IF lv_current_document2 IS INITIAL.
        MODIFY ENTITIES OF zdd_einvoice
          ENTITY zdd_einvoice
          CREATE FIELDS (
            billingdocument
            companycode
            plant
            ewaybillstatus
            ewbno
            ewbdt
            ewbvalidtill
            createddate
          )
          WITH VALUE #(
            (
              %cid            = 'EWB_CREATE_001'
              billingdocument = lv_document
              companycode     = lv_billing-companycode
              plant           = lv_billing-plant
              ewaybillstatus  = 'Generated'
              ewbno           = lv_ewaybill
              ewbdt           = lv_ewbdt
              ewbvalidtill    = lv_ewbvalidtill
              createddate     = sy-datum
            )
          )
          MAPPED DATA(mapped_log)
          FAILED DATA(failed_log)
          REPORTED DATA(reported_log).
      ELSE.
        MODIFY ENTITIES OF zdd_einvoice
          ENTITY zdd_einvoice
          UPDATE FIELDS (
            ewaybillstatus
            ewbno
            ewbdt
            ewbvalidtill
          )
          WITH VALUE #(
            (
              billingdocument = lv_document
              ewaybillstatus  = 'Generated'
              ewbno           = lv_ewaybill
              ewbdt           = lv_ewbdt
              ewbvalidtill    = lv_ewbvalidtill
            )
          )
          MAPPED DATA(mapped_log_up)
          FAILED DATA(failed_log_up)
          REPORTED DATA(reported_log_up).
      ENDIF.

      MODIFY ENTITIES OF zdd_einv_ewb_log
        ENTITY zdd_einv_ewb_log
        CREATE FIELDS (
          billingdocument
          processtype
          status
          ewbno
          httpstatus
          requestpayload
          responsepayload
        )
        WITH VALUE #(
          (
            %cid            = 'EWB_LOG_001'
            billingdocument = lv_document
            processtype     = 'EWAY'
            status          = 'Generated'
            ewbno           = lv_ewaybill
            httpstatus      = '200'
            requestpayload  = lv_request
            responsepayload = lv_response
          )
        )
        MAPPED DATA(mapped_logtable)
        FAILED DATA(failed_logtable)
        REPORTED DATA(reported_logtable).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '001'
          severity = if_abap_behv_message=>severity-success
          v1       = lv_ewaybill
        )
      ) TO reported-zdd_irn.

      APPEND VALUE #(
        %cid   = keys[ 1 ]-%cid
        %param = VALUE #(
          json_payload = |E-Way Bill Generated Successfully : - { lv_ewaybill } valid till { lv_ewbvalidtill }|
        )
      ) TO result.
      RETURN.

    ELSE.

      " NIC error code -> error text   e.g. 240 -> Could not generate eway bill...
      lv_errtext = zcl_ewb_error=>get_error_text( lv_response ).

      IF lv_current_document2 IS INITIAL.
        MODIFY ENTITIES OF zdd_einvoice
          ENTITY zdd_einvoice
          CREATE FIELDS (
            billingdocument
            companycode
            plant
            ewaybillstatus
            createddate
          )
          WITH VALUE #(
            (
              %cid            = 'EWB_CREATE_001'
              billingdocument = lv_document
              companycode     = lv_billing-companycode
              plant           = lv_billing-plant
              ewaybillstatus  = 'Rejected'
              createddate     = sy-datum
            )
          )
          MAPPED DATA(mapped_log_f)
          FAILED DATA(failed_log_f)
          REPORTED DATA(reported_f).
      ELSE.
        MODIFY ENTITIES OF zdd_einvoice
          ENTITY zdd_einvoice
          UPDATE FIELDS ( ewaybillstatus )
          WITH VALUE #(
            (
              billingdocument = lv_document
              ewaybillstatus  = 'Rejected'
            )
          )
          MAPPED DATA(mapped_log_f2)
          FAILED DATA(failed_log_f2)
          REPORTED DATA(reported_f2).
      ENDIF.

      MODIFY ENTITIES OF zdd_einv_ewb_log
        ENTITY zdd_einv_ewb_log
        CREATE FIELDS (
          billingdocument
          processtype
          status
          httpstatus
          requestpayload
          responsepayload
        )
        WITH VALUE #(
          (
            %cid            = 'EWB_LOG_001'
            billingdocument = lv_document
            processtype     = 'EWAY'
            status          = 'Rejected'
            httpstatus      = '400'
            requestpayload  = lv_request
            responsepayload = COND #( WHEN lv_response IS INITIAL
                                      THEN 'No response from CPI'
                                      ELSE |{ lv_errtext } | && lv_response )
          )
        )
        MAPPED DATA(mapped_logtable_f)
        FAILED DATA(failed_logtable_f)
        REPORTED DATA(reported_logtable_f).

      DATA(lv_first) = COND string( WHEN lv_errtext CS |\n|
                            THEN substring_before( val = lv_errtext sub = |\n| )
                            ELSE lv_errtext ).

      APPEND VALUE #(
        %cid = keys[ 1 ]-%cid
        %msg = new_message(
          id       = 'ZIRN'
          number   = '003'
          severity = if_abap_behv_message=>severity-error
          v1       = get_odn( lv_document )                       " ODN
          v2       = substring( val = lv_first
                                len = nmin( val1 = 50 val2 = strlen( lv_first ) ) )
        )
      ) TO reported-zdd_irn.

*      APPEND VALUE #(
*        %cid = keys[ 1 ]-%cid
*        %msg = new_message(
*          id       = 'ZIRN'
*          number   = '003'
*          severity = if_abap_behv_message=>severity-error
*          v1       = lv_document
*          v2       = substring( val = lv_errtext
*                                len = nmin( val1 = 50 val2 = strlen( lv_errtext ) ) )
*        )
*      ) TO reported-zdd_irn.

      APPEND VALUE #(
        %cid   = keys[ 1 ]-%cid
        %param = VALUE #( json_payload = lv_errtext )
      ) TO result.
      RETURN.

    ENDIF.

  ENDMETHOD.

  METHOD updateewaybilldetails.

    DATA lv_billing TYPE zdt_einvoice-billingdocument.
    DATA lv_date    TYPE d.
    DATA lv_message TYPE string.
    DATA ls_param   TYPE zst_ewaybill_details.

    READ TABLE keys INDEX 1 INTO DATA(ls_key).
    IF sy-subrc <> 0 OR ls_key-%param IS INITIAL.
      APPEND VALUE #( %cid   = ls_key-%cid
                      %param = VALUE #( json_payload = 'Action parameter is missing' ) ) TO result.
      RETURN.
    ENDIF.

    ls_param = CORRESPONDING #( ls_key-%param ).

    IF ls_param-billingdocument IS INITIAL.
      APPEND VALUE #( %cid   = ls_key-%cid
                      %param = VALUE #( json_payload = 'Billing Document is required' ) ) TO result.
      RETURN.
    ENDIF.

    lv_billing = |{ ls_param-billingdocument ALPHA = IN }|.
    lv_date    = ls_key-%param-transportdocdate.

    DATA(lv_odn) = get_odn( lv_billing ).

    IF ls_param-transportername IS INITIAL
       AND ls_param-transporterid IS NOT INITIAL
       AND strlen( condense( CONV string( ls_param-transporterid ) ) ) <= 10.

      DATA lv_supplier TYPE i_supplier-supplier.
      lv_supplier = condense( CONV string( ls_param-transporterid ) ).
      lv_supplier = |{ lv_supplier ALPHA = IN }|.

      SELECT SINGLE FROM i_supplier
        FIELDS suppliername
        WHERE supplier = @lv_supplier
        INTO @DATA(lv_supname).

      IF sy-subrc = 0.
        ls_param-transportername = lv_supname.
      ENDIF.
    ENDIF.


    SELECT SINGLE FROM zdt_einvoice
      FIELDS billingdocument
      WHERE billingdocument = @lv_billing
      INTO @DATA(lv_exists).


    IF sy-subrc = 0.

      MODIFY ENTITIES OF zdd_einvoice
        ENTITY zdd_einvoice
        UPDATE FIELDS ( transporterid transportergstin transportername
                        transportdocnumber transportdocdate modeoftransport
                        vehicletype distancekm vehiclenumber )
        WITH VALUE #( ( billingdocument    = lv_billing
                        transporterid      = ls_param-transporterid
                        transportergstin   = ls_param-transportergstin
                        transportername    = ls_param-transportername
                        transportdocnumber = ls_param-transportdocnumber
                        transportdocdate   = lv_date
                        modeoftransport    = ls_param-modeoftransport
                        vehicletype        = ls_param-vehicletype
                        distancekm         = ls_param-distancekm
                        vehiclenumber      = ls_param-vehiclenumber ) )
        FAILED   DATA(ls_failed_up)
        REPORTED DATA(ls_reported_up).

      IF ls_failed_up IS NOT INITIAL.
        DATA(lv_cause) = `unknown`.
        IF ls_failed_up-zdd_einvoice IS NOT INITIAL.
          CASE ls_failed_up-zdd_einvoice[ 1 ]-%fail-cause.
            WHEN if_abap_behv=>cause-unauthorized. lv_cause = `not authorized`.
            WHEN if_abap_behv=>cause-locked.       lv_cause = `locked by another user/session`.
            WHEN if_abap_behv=>cause-not_found.    lv_cause = `record not found`.
            WHEN if_abap_behv=>cause-readonly.     lv_cause = `field is read-only`.
            WHEN if_abap_behv=>cause-disabled.     lv_cause = `update disabled`.
            WHEN if_abap_behv=>cause-conflict.     lv_cause = `conflict`.
            WHEN OTHERS.                           lv_cause = `unspecific`.
          ENDCASE.
        ENDIF.
        IF ls_reported_up-zdd_einvoice IS NOT INITIAL
           AND ls_reported_up-zdd_einvoice[ 1 ]-%msg IS BOUND.
          lv_cause = |{ lv_cause } - { ls_reported_up-zdd_einvoice[ 1 ]-%msg->if_message~get_text( ) }|.
        ENDIF.
        lv_message = |Transporter details could not be modified for ODN { lv_odn }: { lv_cause }|.
      ELSE.
        lv_message = |Transporter details modified successfully for ODN { lv_odn }|.
      ENDIF.

    ELSE.

      SELECT SINGLE FROM i_billingdocumentitem
        FIELDS plant, companycode
        WHERE billingdocument = @lv_billing
        INTO @DATA(ls_bill).

      IF sy-subrc <> 0.
        APPEND VALUE #( %cid   = ls_key-%cid
                        %param = VALUE #( json_payload = |Billing Document { lv_billing } not found| ) ) TO result.
        RETURN.
      ENDIF.

      MODIFY ENTITIES OF zdd_einvoice
        ENTITY zdd_einvoice
        CREATE FIELDS ( billingdocument companycode plant
                        transporterid transportergstin transportername
                        transportdocnumber transportdocdate modeoftransport
                        vehicletype distancekm vehiclenumber createddate )
        WITH VALUE #( ( %cid               = 'TRANSPORT_CREATE_001'
                        billingdocument    = lv_billing
                        companycode        = ls_bill-companycode
                        plant              = ls_bill-plant
                        transporterid      = ls_param-transporterid
                        transportergstin   = ls_param-transportergstin
                        transportername    = ls_param-transportername
                        transportdocnumber = ls_param-transportdocnumber
                        transportdocdate   = lv_date
                        modeoftransport    = ls_param-modeoftransport
                        vehicletype        = ls_param-vehicletype
                        distancekm         = ls_param-distancekm
                        vehiclenumber      = ls_param-vehiclenumber
                        createddate        = cl_abap_context_info=>get_system_date( ) ) )
        MAPPED   DATA(ls_mapped_cr)
        FAILED   DATA(ls_failed_cr)
        REPORTED DATA(ls_reported_cr).

      IF ls_failed_cr IS INITIAL.
        lv_message = |Transporter details saved successfully for ODN { lv_odn }|.
      ELSE.
        lv_message = |Transporter details could not be saved for ODN { lv_odn }|.
      ENDIF.

    ENDIF.

    APPEND VALUE #( %cid   = ls_key-%cid
                    %param = VALUE #( json_payload = lv_message ) ) TO result.

  ENDMETHOD.

  METHOD get_odn.
    SELECT SINGLE FROM i_billingdocument
      FIELDS documentreferenceid
      WHERE billingdocument = @iv_billingdocument
      INTO @DATA(lv_odn).

    rv_odn = condense( CONV string( lv_odn ) ).

    IF rv_odn IS INITIAL.
      rv_odn = |{ iv_billingdocument ALPHA = OUT }|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

