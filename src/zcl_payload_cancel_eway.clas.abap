CLASS zcl_payload_cancel_eway DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS get_payload
      IMPORTING
        VALUE(billingdocument) TYPE i_billingdocument-billingdocument
      RETURNING
        VALUE(rv_payload)      TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PAYLOAD_CANCEL_EWAY IMPLEMENTATION.


  METHOD get_payload.

    TYPES: BEGIN OF ty_inv,
             ewbNo         TYPE int8,
             cancelRsnCode TYPE i,
             cancelRmrk    TYPE string,
             plant         TYPE string,
           END OF ty_inv.

    DATA: ls_payload TYPE ty_inv.

    SELECT SINGLE FROM
    zdd_irn AS a
    FIELDS
    a~irn,
    a~BillingDocument,
    a~Ewbno
    WHERE a~BillingDocument = @billingdocument
    INTO @DATA(lv_billing).

    IF sy-subrc <> 0 OR lv_billing-Ewbno IS INITIAL.
      rv_payload = |\{"Error":"No E-Way Bill found for billing document { billingdocument }"\}|.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM i_billingdocumentitem
      FIELDS plant
      WHERE billingdocument = @billingdocument
        AND plant <> ''
      INTO @DATA(lv_plant).

    IF sy-subrc <> 0.
      rv_payload = |\{"Error":"No plant found on billing document { billingdocument }"\}|.
      RETURN.
    ENDIF.

    ls_payload-ewbNo         = CONV int8( condense( CONV string( lv_billing-Ewbno ) ) ).
    ls_payload-cancelrsncode = 3.
    ls_payload-cancelrmrk    = 'Wrong entry'.
    ls_payload-plant         = CONV string( lv_plant ).

    DATA lt_mapping TYPE /ui2/cl_json=>name_mappings.

    lt_mapping = VALUE #(
        ( abap = to_upper( 'ewbNo' )         json = 'ewbNo' )
        ( abap = to_upper( 'cancelRsnCode' ) json = 'cancelRsnCode' )
        ( abap = to_upper( 'cancelRmrk' )    json = 'cancelRmrk' )
        ( abap = to_upper( 'plant' )         json = 'plant' )
    ).

    DATA(lv_json) = /ui2/cl_json=>serialize(
                  data          = ls_payload
                  pretty_name   = /ui2/cl_json=>pretty_mode-none
                  name_mappings = lt_mapping
                  ).

    rv_payload = lv_json.

  ENDMETHOD.
ENDCLASS.
