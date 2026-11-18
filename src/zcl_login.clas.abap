CLASS zcl_login DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_LOGIN IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA ls_login    TYPE zgsp_login.
    DATA lv_password TYPE zgsp_login-gc_password.

    lv_password = ''.

    SELECT SINGLE * FROM zgsp_login
      WHERE plant = '1001'
      INTO @ls_login.

    ls_login-plant       = '1001'.
    ls_login-gc_gstin    = '05AAACI2322L1ZW'.
    ls_login-gc_username = 'Panaacea2050'.

    IF lv_password IS NOT INITIAL.
      ls_login-gc_password = lv_password.
    ENDIF.

    IF ls_login-gc_password IS INITIAL.
      out->write( 'Password is blank - enter it in lv_password and run again' ).
      RETURN.
    ENDIF.

    MODIFY zgsp_login FROM @ls_login.

    IF sy-subrc = 0.
      COMMIT WORK.
      out->write( |Saved login data for plant { ls_login-plant }| ).
    ELSE.
      out->write( 'Save failed' ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
