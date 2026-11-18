CLASS zcl_generate_irn DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS generate_irn
      IMPORTING
        VALUE(billingdocument) TYPE I_BillingDocument-BillingDocument
      RETURNING
        VALUE(lv_response)     TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_GENERATE_IRN IMPLEMENTATION.


  METHOD generate_irn.

    DATA:
      lv_url     TYPE string,
      lv_payload TYPE string.

    TRY.
        DATA(lv_system_url) = to_lower( cl_abap_context_info=>get_system_url( ) ).

        IF lv_system_url CS 'my444681'.
          lv_url = 'https://application-dev-test-75u4yj1b.it-cpi021-rt.cfapps.in30.hana.ondemand.com/http/EInvoice/GenerateIRN/Prd'.
        ELSE.
          lv_url = 'https://application-dev-test-75u4yj1b.it-cpi021-rt.cfapps.in30.hana.ondemand.com/http/EInvoice/GenerateIRN/Dev'.
        ENDIF.

        DATA(lo_destination) =
          cl_http_destination_provider=>create_by_url(
            lv_url ).

        DATA(lo_client) =
          cl_web_http_client_manager=>create_by_http_destination(
            lo_destination ).

        DATA(lo_request) =
          lo_client->get_http_request( ).

        lv_payload =
          zcl_payload_irn=>get_payload(
            billingdocument = billingdocument ).

        IF lv_payload CS '"Error"'.
          lv_response = lv_payload.
          RETURN.
        ENDIF.

        lo_request->set_header_field(
          i_name  = 'Accept'
          i_value = 'application/json'
        ).

        lo_request->set_header_field(
          i_name  = 'Content-Type'
          i_value = 'application/json'
        ).

        lo_request->set_text( lv_payload ).

        lo_request->set_authorization_basic(
          i_username = 'sb-6b0eebe6-1d97-44c2-9d1f-eeb0a5ec49e2!b46708|it-rt-application-dev-test-75u4yj1b!b148'
          i_password = '7554f861-d47b-4cae-9ce0-032ab80af227$uYgaFSWBNAg7-02hmWmTfLgeM1EV7IiLb0jcx2PoM34='
        ).

        DATA(lo_response) =
          lo_client->execute(
            if_web_http_client=>post ).

        DATA(ls_status) =
          lo_response->get_status( ).

        lv_response =
          lo_response->get_text( ).

        IF ls_status-code < 200 OR ls_status-code >= 300.

          IF lv_response IS INITIAL.
            lv_response =
              |HTTP Error { ls_status-code } { ls_status-reason }|.
          ENDIF.

          RETURN.

        ENDIF.

      CATCH cx_http_dest_provider_error INTO DATA(lx_dest).
        lv_response =
          |Destination error: { lx_dest->get_text( ) }|.

      CATCH cx_web_http_client_error INTO DATA(lx_http).
        lv_response =
          |HTTP client error: { lx_http->get_text( ) }|.

      CATCH cx_web_message_error INTO DATA(lx_message).
        lv_response =
          |Web message error: { lx_message->get_text( ) }|.

      CATCH cx_root INTO DATA(lx_root).
        lv_response =
          |Unexpected error: { lx_root->get_text( ) }|.

    ENDTRY.

  ENDMETHOD.
ENDCLASS.
