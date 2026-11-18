CLASS lhc_ZDD_EINV_EWB_LOG DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR zdd_einv_ewb_log RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR zdd_einv_ewb_log RESULT result.

ENDCLASS.

CLASS lhc_ZDD_EINV_EWB_LOG IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
    result = VALUE #(
       %create = if_abap_behv=>auth-allowed
     ).
  ENDMETHOD.

ENDCLASS.
