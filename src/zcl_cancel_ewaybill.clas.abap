CLASS zcl_cancel_ewaybill DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
*    CLASS-METHODS cancel_irn
*      IMPORTING
*        VALUE(billingdocument) TYPE i_billingdocument-billingdocument
*        VALUE(iv_payload)      TYPE string OPTIONAL
*      RETURNING
*        VALUE(lv_response)     TYPE string.
    CLASS-METHODS cancel_irn
      IMPORTING
        billingdocument    TYPE i_billingdocument-billingdocument
        iv_payload         TYPE string OPTIONAL
      RETURNING
        VALUE(lv_response) TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CANCEL_EWAYBILL IMPLEMENTATION.


  METHOD cancel_irn.

    DATA:
      lv_url     TYPE string,
      lv_payload TYPE string.

    lv_payload = COND #( WHEN iv_payload IS NOT INITIAL
                         THEN iv_payload
                         ELSE zcl_payload_cancel_eway=>get_payload( billingdocument = billingdocument ) ).

    IF lv_payload CS '"Error"'.
      lv_response = lv_payload.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_system_url) = to_lower( cl_abap_context_info=>get_system_url( ) ).

        IF lv_system_url CS 'my444681'.
          lv_url = 'https://application-dev-test-75u4yj1b.it-cpi021-rt.cfapps.in30.hana.ondemand.com/http/EWayBill/Cancel/Prd'.
        ELSE.
          lv_url = 'https://application-dev-test-75u4yj1b.it-cpi021-rt.cfapps.in30.hana.ondemand.com/http/EWayBill/Cancel/Dev'.
        ENDIF.
        DATA(lo_dest)    = cl_http_destination_provider=>create_by_url( lv_url ).
        DATA(lo_client)  = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).
        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_header_field( i_name = 'Accept'       i_value = 'application/json' ).
        lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).

        lo_request->set_authorization_basic(
          i_username = 'sb-6b0eebe6-1d97-44c2-9d1f-eeb0a5ec49e2!b46708|it-rt-application-dev-test-75u4yj1b!b148'
          i_password = '7554f861-d47b-4cae-9ce0-032ab80af227$uYgaFSWBNAg7-02hmWmTfLgeM1EV7IiLb0jcx2PoM34='
        ).

        lo_request->set_text( lv_payload ).

        DATA(lo_response) = lo_client->execute( if_web_http_client=>post ).
        DATA(ls_status)   = lo_response->get_status( ).
        lv_response       = lo_response->get_text( ).

        IF ls_status-code < 200 OR ls_status-code >= 300.
          IF lv_response IS INITIAL.
            lv_response = |\{"CpiError":"HTTP { ls_status-code } { ls_status-reason }"\}|.
          ENDIF.
          lo_client->close( ).
          RETURN.
        ENDIF.

        lo_client->close( ).
        RETURN.

         CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error
            cx_abap_context_info_error INTO DATA(lx_error).
        lv_response = |\{"CpiError":"{ lx_error->get_text( ) }"\}|.
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
