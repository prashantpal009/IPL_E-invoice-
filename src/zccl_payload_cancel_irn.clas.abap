*CLASS zccl_payload_cancel_irn DEFINITION
*  PUBLIC
*  FINAL
*  CREATE PUBLIC .
*
*  PUBLIC SECTION.
*    CLASS-METHODS get_payload
*      IMPORTING
*        VALUE(billingdocument) TYPE I_BillingDocument-BillingDocument
*      RETURNING
*        VALUE(rv_payload)      TYPE string.
*  PROTECTED SECTION.
*  PRIVATE SECTION.
*ENDCLASS.
*
*
*
*CLASS ZCCL_PAYLOAD_CANCEL_IRN IMPLEMENTATION.
*
*
*  METHOD get_payload.
*    TYPES: BEGIN OF ty_inv,
*             irn       TYPE string,
*             cnlRsn    TYPE string,
*             cnlRem    TYPE string,
*           END OF ty_inv.
*
*    DATA: ls_payload TYPE ty_inv.
*
*    SELECT SINGLE FROM
*    zdd_irn AS a
*    FIELDS
*    a~irn,
*    a~BillingDocument
*    WHERE a~BillingDocument = @billingdocument
*    INTO @DATA(lv_billing).
*
*    SELECT SINGLE FROM
*    i_billingdocument AS a
*    LEFT JOIN i_customer AS b ON a~soldtoparty = b~customer
*    FIELDS
*    b~taxnumber3
*    WHERE a~billingdocument = @billingdocument
*    INTO @DATA(lv_usergstin).
*
*    ls_payload-irn = lv_billing-Irn.
*    ls_payload-cnlrsn = '1'.
*    ls_payload-cnlrem = 'Wrong entry'.
*
*    DATA lt_mapping TYPE /ui2/cl_json=>name_mappings.
*
*    lt_mapping = VALUE #(
*
*        ( abap = to_upper( 'irn' ) json = 'irn' )
*        ( abap = to_upper( 'cnlRsn' ) json = 'cnlRsn' )
*        ( abap = to_upper( 'cnlRem' ) json = 'cnlRem' )
*
*    ).
*
*    DATA(lv_json) = /ui2/cl_json=>serialize(
*                  data        = ls_payload
*                  pretty_name = /ui2/cl_json=>pretty_mode-none
*                  name_mappings = lt_mapping
*                  ).
*
*    REPLACE ALL OCCURRENCES OF ':""' IN lv_json WITH ':null'.
*
*    rv_payload = lv_json.
*
*  ENDMETHOD.
*ENDCLASS.

CLASS zccl_payload_cancel_irn DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS get_payload
      IMPORTING
        VALUE(billingdocument) TYPE I_BillingDocument-BillingDocument
      RETURNING
        VALUE(rv_payload)      TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCCL_PAYLOAD_CANCEL_IRN IMPLEMENTATION.


  METHOD get_payload.
    TYPES: BEGIN OF ty_inv,
             irn       TYPE string,
             cnlRsn    TYPE string,
             cnlRem    TYPE string,
             plant     TYPE string,
           END OF ty_inv.

    DATA: ls_payload TYPE ty_inv.

    SELECT SINGLE FROM
    zdd_irn AS a
    FIELDS
    a~irn,
    a~BillingDocument
    WHERE a~BillingDocument = @billingdocument
    INTO @DATA(lv_billing).

    IF sy-subrc <> 0 OR lv_billing-Irn IS INITIAL.
      rv_payload = |\{"Error":"No IRN found for billing document { billingdocument }"\}|.
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

    SELECT SINGLE FROM
    i_billingdocument AS a
    LEFT JOIN i_customer AS b ON a~soldtoparty = b~customer
    FIELDS
    b~taxnumber3
    WHERE a~billingdocument = @billingdocument
    INTO @DATA(lv_usergstin).

    ls_payload-irn    = lv_billing-Irn.
    ls_payload-cnlrsn = '1'.
    ls_payload-cnlrem = 'Wrong entry'.
    ls_payload-plant  = CONV string( lv_plant ).

    DATA lt_mapping TYPE /ui2/cl_json=>name_mappings.

    lt_mapping = VALUE #(

        ( abap = to_upper( 'irn' )    json = 'irn' )
        ( abap = to_upper( 'cnlRsn' ) json = 'cnlRsn' )
        ( abap = to_upper( 'cnlRem' ) json = 'cnlRem' )
        ( abap = to_upper( 'plant' )  json = 'plant' )

    ).

    DATA(lv_json) = /ui2/cl_json=>serialize(
                  data        = ls_payload
                  pretty_name = /ui2/cl_json=>pretty_mode-none
                  name_mappings = lt_mapping
                  ).

    REPLACE ALL OCCURRENCES OF ':""' IN lv_json WITH ':null'.

    rv_payload = lv_json.

  ENDMETHOD.
ENDCLASS.
