CLASS lhc_plantgst DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PlantGst RESULT result.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE PlantGst.

ENDCLASS.


CLASS lhc_plantgst IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Access is controlled by the business role (IAM app / catalog) - allow all operations
    result-%create      = if_abap_behv=>auth-allowed.
    result-%update      = if_abap_behv=>auth-allowed.
    result-%delete      = if_abap_behv=>auth-allowed.
    result-%action-Edit = if_abap_behv=>auth-allowed.
  ENDMETHOD.


  METHOD precheck_create.
    CHECK entities IS NOT INITIAL.

    SELECT plant, gstin
      FROM zplant_gst
      FOR ALL ENTRIES IN @entities
      WHERE plant = @entities-Plant
        AND gstin = @entities-Gstin
      INTO TABLE @DATA(lt_existing).

    SELECT plant, gstin
      FROM zplant_gst_d
      FOR ALL ENTRIES IN @entities
      WHERE plant = @entities-Plant
        AND gstin = @entities-Gstin
      APPENDING TABLE @lt_existing.

    CHECK lt_existing IS NOT INITIAL.

    LOOP AT entities INTO DATA(ls_entity).
      IF line_exists( lt_existing[ plant = ls_entity-Plant gstin = ls_entity-Gstin ] ).
        APPEND VALUE #( %cid      = ls_entity-%cid
                        %is_draft = ls_entity-%is_draft
                        %key      = ls_entity-%key ) TO failed-plantgst.

        APPEND VALUE #( %cid           = ls_entity-%cid
                        %is_draft      = ls_entity-%is_draft
                        %key           = ls_entity-%key
                        %msg           = new_message( id       = 'ZMSG_PLANTGST'
                                                      number   = '008'
                                                      severity = if_abap_behv_message=>severity-error
                                                      v1       = ls_entity-Plant
                                                      v2       = ls_entity-Gstin )
                        %element-Plant = if_abap_behv=>mk-on
                        %element-Gstin = if_abap_behv=>mk-on ) TO reported-plantgst.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
