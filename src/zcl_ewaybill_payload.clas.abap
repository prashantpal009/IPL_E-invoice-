CLASS zcl_ewaybill_payload DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.


    CLASS-METHODS get_credentials
      IMPORTING
        VALUE(billingdocument) TYPE i_billingdocument-billingdocument
      EXPORTING
        ev_gstin               TYPE string
        ev_username            TYPE string
        ev_password            TYPE string.

    CLASS-METHODS generate_payload
      IMPORTING
        VALUE(billingdocument) TYPE i_billingdocument-billingdocument


      RETURNING
        VALUE(rv_payload)      TYPE string.

    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS split_addr
      IMPORTING iv_addr  TYPE string
      EXPORTING ev_part1 TYPE string
                ev_part2 TYPE string.

    CLASS-METHODS get_seller_gstin
      IMPORTING iv_billingdocument TYPE i_billingdocument-billingdocument
      RETURNING VALUE(rv_gstin)    TYPE string.


    CLASS-METHODS clean
      IMPORTING iv_text        TYPE string
                iv_len         TYPE i DEFAULT 100
      RETURNING VALUE(rv_text) TYPE string.

    CLASS-METHODS get_state_code
      IMPORTING iv_country     TYPE string
                iv_region      TYPE string
                iv_region_name TYPE string OPTIONAL
      RETURNING VALUE(rv_code) TYPE i.

    CLASS-METHODS map_uqc
      IMPORTING iv_sap_uom    TYPE string
      RETURNING VALUE(rv_uqc) TYPE string.

ENDCLASS.



CLASS ZCL_EWAYBILL_PAYLOAD IMPLEMENTATION.


  METHOD get_seller_gstin.

    SELECT SINGLE FROM i_billingdocumentitem
      FIELDS plant
      WHERE billingdocument = @iv_billingdocument
        AND plant <> ''
      INTO @DATA(lv_plant).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM zplant_gst
      FIELDS gstin
      WHERE plant = @lv_plant
      INTO @rv_gstin.

    IF rv_gstin IS INITIAL.

      SELECT SINGLE FROM i_plant AS pl
        LEFT OUTER JOIN i_customer AS c ON c~customer = pl~plantcustomer
        LEFT OUTER JOIN i_supplier AS s ON s~supplier = pl~plantsupplier
        FIELDS c~taxnumber3 AS cust_gstin,
               s~taxnumber3 AS supp_gstin
        WHERE pl~plant = @lv_plant
        INTO @DATA(ls_master).

      rv_gstin = COND #( WHEN ls_master-cust_gstin IS NOT INITIAL
                         THEN ls_master-cust_gstin
                         ELSE ls_master-supp_gstin ).
    ENDIF.

    rv_gstin = to_upper( condense( rv_gstin ) ).

  ENDMETHOD.


  METHOD get_credentials.

    CLEAR: ev_gstin, ev_username, ev_password.

    SELECT SINGLE FROM i_billingdocumentitem
      FIELDS plant
      WHERE billingdocument = @billingdocument
        AND plant <> ''
      INTO @DATA(lv_plant).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM zplant_gst
      FIELDS gstin, user_id, password
      WHERE plant = @lv_plant
      INTO ( @ev_gstin, @ev_username, @ev_password ).

  ENDMETHOD.


  METHOD generate_payload.

    TYPES:
      BEGIN OF ty_item,
        productName   TYPE string,
        productDesc   TYPE string,
        hsnCode       TYPE int8,
        quantity      TYPE decfloat34,
        qtyUnit       TYPE string,
        cgstRate      TYPE decfloat34,
        sgstRate      TYPE decfloat34,
        igstRate      TYPE decfloat34,
        cessRate      TYPE decfloat34,
        cessNonAdvol  TYPE decfloat34,
        taxableAmount TYPE decfloat34,
      END OF ty_item.

    TYPES:
      tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_plant_dtls,
        plant TYPE string,
      END OF ty_plant_dtls.

    TYPES:
      BEGIN OF ty_payload,
        plantDtls             TYPE ty_plant_dtls,     " first node: PlantDetails
        supplyType            TYPE string,
        subSupplyType         TYPE string,
        subSupplyDesc         TYPE string,
        docType               TYPE string,
        docNo                 TYPE string,
        docDate               TYPE string,
        fromGstin             TYPE string,
        fromTrdName           TYPE string,
        fromAddr1             TYPE string,
        fromAddr2             TYPE string,
        fromPlace             TYPE string,
        fromPincode           TYPE i,
        actFromStateCode      TYPE i,
        fromStateCode         TYPE i,
        toGstin               TYPE string,
        toTrdName             TYPE string,
        toAddr1               TYPE string,
        toAddr2               TYPE string,
        toPlace               TYPE string,
        toPincode             TYPE i,
        actToStateCode        TYPE i,
        toStateCode           TYPE i,
        transactionType       TYPE i,
        dispatchFromGSTIN     TYPE string,
        dispatchFromTradeName TYPE string,
        shipToGSTIN           TYPE string,
        shipToTradeName       TYPE string,
        otherValue            TYPE decfloat34,
        totalValue            TYPE decfloat34,
        cgstValue             TYPE decfloat34,
        sgstValue             TYPE decfloat34,
        igstValue             TYPE decfloat34,
        cessValue             TYPE decfloat34,
        cessNonAdvolValue     TYPE decfloat34,
        totInvValue           TYPE decfloat34,
        transporterId         TYPE string,
        transporterName       TYPE string,
        transDocNo            TYPE string,
        transMode             TYPE string,
        transDistance         TYPE string,
        transDocDate          TYPE string,
        vehicleNo             TYPE string,
        vehicleType           TYPE string,
        itemList              TYPE tt_item,
      END OF ty_payload.


    DATA:
      ls_payload TYPE ty_payload,
      ls_item    TYPE ty_item.

    SELECT SINGLE FROM i_billingdocument
      FIELDS billingdocument, billingdocumenttype, billingdocumentdate,
             distributionchannel, transactioncurrency, accountingexchangerate,
             billingdocumentiscancelled,documentreferenceid
      WHERE billingdocument = @billingdocument
      INTO @DATA(hd).

    IF sy-subrc <> 0.
      rv_payload = |\{"Error":"Billing document { billingdocument } not found"\}|.
      RETURN.
    ENDIF.

    IF hd-billingdocumentiscancelled = abap_true.
      rv_payload = |\{"Error":"Billing document is cancelled"\}|.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM i_billingdocumentitem
      FIELDS plant, companycode
      WHERE billingdocument = @billingdocument AND plant <> ''
      INTO @DATA(ls_pl).

    ls_payload-plantDtls-plant = ls_pl-plant.

    DATA(lv_rate) = CONV decfloat34( 1 ).
    IF hd-transactioncurrency <> 'INR'.
      lv_rate = CONV decfloat34( hd-accountingexchangerate ).
      IF lv_rate < 0.
        lv_rate = 1 / abs( lv_rate ).
      ENDIF.
      IF lv_rate = 0.
        rv_payload = |\{"Error":"No exchange rate for currency { hd-transactioncurrency }"\}|.
        RETURN.
      ENDIF.
    ENDIF.


    SELECT SINGLE FROM zdt_einvoice
      FIELDS ewbno, ewaybillstatus,
             transporterid, transportergstin, transportername,
             transportdocnumber, transportdocdate,
             modeoftransport, vehicletype, distancekm, vehiclenumber
      WHERE billingdocument = @billingdocument
      INTO @DATA(ls_tr).

    IF sy-subrc <> 0.
      rv_payload = |\{"Error":"Transport details not maintained — use Update E-Way Bill details"\}|.
      RETURN.
    ENDIF.

*    IF ls_tr-ewbno IS NOT INITIAL AND ls_tr-ewaybillstatus <> 'Cancelled'.
*      rv_payload = |\{"Error":"E-Way Bill { ls_tr-ewbno } already generated"\}|.
*      RETURN.
*    ENDIF.
*

    DATA(lv_ewb_status) = to_upper( condense( CONV string( ls_tr-ewaybillstatus ) ) ).

    IF ls_tr-ewbno IS NOT INITIAL
       AND lv_ewb_status NS 'CANCEL'
       AND lv_ewb_status NS 'REJECT'.
      rv_payload = |\{"Error":"E-Way Bill { ls_tr-ewbno } already generated | &&
                   |— it can be generated again only if it is Cancelled or Rejected"\}|.
      RETURN.
    ENDIF.
    SELECT SINGLE FROM i_plant AS pl
      LEFT OUTER JOIN i_address_2 WITH PRIVILEGED ACCESS AS a ON a~addressid = pl~addressid
      FIELDS pl~plantname, a~housenumber, a~streetname,
             a~streetprefixname1, a~streetsuffixname1,
             a~districtname, a~cityname, a~postalcode
      WHERE pl~plant = @ls_pl-plant
      INTO @DATA(ls_padr).

    DATA(lv_gstin) = get_seller_gstin( billingdocument ).

    IF strlen( lv_gstin ) <> 15.
      rv_payload = |\{"Error":"Seller GSTIN not found for plant { ls_pl-plant } | &&
                   |— maintain it in ZPLANT_GST or in the plant's customer master"\}|.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM zplant_gst
    FIELDS description
    WHERE plant = @ls_pl-plant
    INTO @DATA(lv_trdnm).

    ls_payload-fromGstin   = lv_gstin.
    ls_payload-fromTrdName = clean( COND #( WHEN lv_trdnm IS NOT INITIAL
                                            THEN CONV string( lv_trdnm )
                                            ELSE CONV string( ls_padr-plantname ) ) ).

    split_addr( EXPORTING iv_addr  = |{ ls_padr-housenumber } { ls_padr-streetname } | &&
                                     |{ ls_padr-streetprefixname1 } { ls_padr-streetsuffixname1 } | &&
                                     |{ ls_padr-districtname }|
                IMPORTING ev_part1 = ls_payload-fromAddr1
                          ev_part2 = ls_payload-fromAddr2 ).

    ls_payload-fromPlace        = clean( iv_text = CONV string( ls_padr-cityname ) iv_len = 50 ).
    ls_payload-fromPincode      = CONV i( ls_padr-postalcode ).
    ls_payload-fromStateCode    = CONV i( substring( val = lv_gstin len = 2 ) ).
    ls_payload-actFromStateCode = ls_payload-fromStateCode.

    IF strlen( condense( ls_payload-fromAddr1 ) ) < 3.
      rv_payload = |\{"Error":"Address missing for plant { ls_pl-plant } | &&
                   |— maintain the plant address in Manage Plants"\}|.
      RETURN.
    ENDIF.

    DATA lv_disp TYPE abap_bool.

    SELECT SINGLE FROM i_billingdocumentitem
      FIELDS referencesddocument
      WHERE billingdocument             = @billingdocument
        AND referencesddocumentcategory = 'J'
      INTO @DATA(lv_delivery).

    IF lv_delivery IS NOT INITIAL.

      SELECT SINGLE FROM i_deliverydocument
        FIELDS yy1_name_dlh,
               yy1_dispatchadd1_dlh,
               yy1_dispatchadd2_dlh,
               yy1_dispatchstatecode_dlh,
               yy1_dispatchareacity_dlh,
               yy1_dispatchpincode_dlh
        WHERE deliverydocument = @lv_delivery
        INTO @DATA(ls_disp).

      IF ls_disp-yy1_dispatchadd1_dlh IS NOT INITIAL.

        IF ls_disp-yy1_name_dlh IS INITIAL.
          rv_payload = |\{"Error":"Dispatch name missing on delivery { lv_delivery }"\}|.
          RETURN.
        ENDIF.

        lv_disp = abap_true.

        ls_payload-dispatchFromGSTIN     = lv_gstin.
        ls_payload-dispatchFromTradeName = clean( CONV string( ls_disp-yy1_name_dlh ) ).

        split_addr( EXPORTING iv_addr  = |{ ls_disp-yy1_dispatchadd1_dlh } { ls_disp-yy1_dispatchadd2_dlh }|
                    IMPORTING ev_part1 = ls_payload-fromAddr1
                              ev_part2 = ls_payload-fromAddr2 ).

        ls_payload-fromPlace   = clean( iv_text = CONV string( ls_disp-yy1_dispatchareacity_dlh ) iv_len = 50 ).
        DATA(lv_disp_pin) = condense( CONV string( ls_disp-yy1_dispatchpincode_dlh ) ).
        REPLACE ALL OCCURRENCES OF PCRE '[^0-9]' IN lv_disp_pin WITH ''.
        ls_payload-fromPincode = COND i( WHEN lv_disp_pin IS NOT INITIAL
                                         THEN CONV i( lv_disp_pin ) ELSE 0 ).

        DATA(lv_disp_st) = condense( CONV string( ls_disp-yy1_dispatchstatecode_dlh ) ).
        IF matches( val = lv_disp_st pcre = '^[0-9]{1,2}$' ).
          ls_payload-actFromStateCode = CONV i( lv_disp_st ).
        ELSE.
          ls_payload-actFromStateCode = get_state_code( iv_country = 'IN' iv_region = lv_disp_st ).
        ENDIF.

        IF ls_payload-actFromStateCode = 0.
          rv_payload = |\{"Error":"Dispatch state code { lv_disp_st } on delivery { lv_delivery } | &&
                       |is not a valid GST state"\}|.
          RETURN.
        ENDIF.

        IF strlen( condense( ls_payload-fromAddr1 ) ) < 3.
          rv_payload = |\{"Error":"Dispatch address missing on delivery { lv_delivery }"\}|.
          RETURN.
        ENDIF.

        IF ls_payload-fromPincode < 100000 OR ls_payload-fromPincode > 999999.
          rv_payload = |\{"Error":"Dispatch pincode on delivery { lv_delivery } must be 6 digits"\}|.
          RETURN.
        ENDIF.

      ENDIF.

    ENDIF.
    SELECT SINGLE FROM i_billingdocumentpartner AS bp
      INNER JOIN i_customer AS c ON c~customer = bp~customer
      LEFT OUTER JOIN i_address_2 WITH PRIVILEGED ACCESS AS a ON a~addressid = c~addressid
      FIELDS c~customer, c~customername, c~taxnumber3, c~country,
             c~cityname, c~postalcode, c~region,
             a~housenumber, a~streetname, a~streetprefixname1,
             a~streetprefixname2, a~streetsuffixname1,
             a~districtname, a~villagename
      WHERE bp~billingdocument = @billingdocument
        AND bp~partnerfunction = 'RE'
      INTO @DATA(ls_by).

    SELECT SINGLE FROM i_billingdocitempartner AS sp
      INNER JOIN i_customer AS c ON c~customer = sp~customer
      LEFT OUTER JOIN i_address_2 WITH PRIVILEGED ACCESS AS a ON a~addressid = c~addressid
      FIELDS c~customer, c~customername, c~taxnumber3, c~country,
             c~cityname, c~postalcode, c~region,
             a~housenumber, a~streetname, a~streetprefixname1,
             a~streetprefixname2, a~streetsuffixname1,
             a~districtname, a~villagename
      WHERE sp~billingdocument = @billingdocument
        AND sp~partnerfunction = 'WE'
      INTO @DATA(ls_sh).

    DATA(lv_export) = xsdbool( hd-distributionchannel = '09'
                            OR ( ls_sh-country IS NOT INITIAL AND ls_sh-country <> 'IN' ) ).

    DATA(lv_ship_diff) = xsdbool( ls_sh-customer IS NOT INITIAL AND ls_sh-customer <> ls_by-customer ).

    DATA(lv_self) = xsdbool( ls_by-taxnumber3 IS NOT INITIAL
                          AND ls_by-taxnumber3 = lv_gstin ).


    DATA(lv_f8_return) = abap_false.
    IF hd-billingdocumenttype = 'F8'.
      SELECT SINGLE FROM i_billingdocumentitem AS bi
        INNER JOIN i_salesdocument AS so ON so~salesdocument = bi~salesdocument
        FIELDS so~salesdocumenttype
        WHERE bi~billingdocument  = @billingdocument
          AND so~salesdocumenttype = 'CBRE'
        INTO @DATA(lv_f8_so_type).
      IF sy-subrc = 0.
        lv_f8_return = abap_true.
      ENDIF.
    ENDIF.

    ls_payload-supplyType = 'O'.

    CASE hd-billingdocumenttype.

      WHEN 'F2'.
        ls_payload-docType       = 'INV'.
        ls_payload-subSupplyType = COND #( WHEN lv_export = abap_true THEN '3' ELSE '1' ).

      WHEN 'JSN' OR 'JSTO'.
        IF lv_self = abap_true.
          ls_payload-docType       = 'CHL'.
          ls_payload-subSupplyType = '5'.
        ELSE.
          ls_payload-docType       = 'INV'.
          ls_payload-subSupplyType = '1'.
        ENDIF.

      WHEN 'F8' OR 'F5'.
        ls_payload-docType = 'CHL'.
        IF lv_f8_return = abap_true.
          ls_payload-supplyType    = 'I'.
          ls_payload-subSupplyType = '7'.
          ls_payload-subSupplyDesc = 'Sales Return'.
        ELSEIF lv_self = abap_true.
          ls_payload-subSupplyType = '5'.
        ELSE.
          ls_payload-subSupplyType = '8'.
          ls_payload-subSupplyDesc = 'Pro forma dispatch'.
        ENDIF.

      WHEN 'G2' OR 'CBRE'.
        ls_payload-supplyType    = 'I'.
        ls_payload-docType       = 'CHL'.
        ls_payload-subSupplyType = '7'.

      WHEN 'L2'.
        rv_payload = |\{"Error":"Debit note has no goods movement | &&
                     |— E-Way Bill is not applicable"\}|.
        RETURN.

      WHEN OTHERS.
        rv_payload = |\{"Error":"Billing type { hd-billingdocumenttype } is not E-Way Bill relevant"\}|.
        RETURN.

    ENDCASE.

    DATA(lv_docno) = condense( CONV string( hd-documentreferenceid ) ).

*    IF lv_docno IS INITIAL.
*      lv_docno = CONV string( hd-billingdocument ).
*    ENDIF.
    IF lv_docno IS INITIAL OR hd-billingdocumenttype = 'F8'.
      lv_docno = CONV string( hd-billingdocument ).
    ENDIF.

    SHIFT lv_docno LEFT DELETING LEADING '0'.
    ls_payload-docNo   = lv_docno.
    ls_payload-docDate = |{ hd-billingdocumentdate+6(2) }/{ hd-billingdocumentdate+4(2) }/{ hd-billingdocumentdate(4) }|.


    ls_payload-toTrdName = clean( CONV string( ls_by-customername ) ).

*----------------------------------------------------------------------*
*   Bill-to / Ship-to address : same sources as tax invoice (ZCL_TAXINVOICE)
*   - ZBILL_SHIP_ADD (by sales order)   -> street lines, city, pincode, region
*   - ZSO_ONETIMECUSTOMER (channel 04)  -> city, pincode, region
*----------------------------------------------------------------------*
    TYPES: BEGIN OF ty_onetime,
             cityname   TYPE string,
             postalcode TYPE string,
             region     TYPE string,
             regionname TYPE string,
           END OF ty_onetime.

    DATA: ls_ot_by    TYPE ty_onetime,
          ls_ot_sh    TYPE ty_onetime,
          ls_ot       TYPE ty_onetime,
          lt_addr_prt TYPE string_table.

    SELECT SINGLE FROM i_billingdocumentitem
      FIELDS salesdocument
      WHERE billingdocument = @billingdocument
        AND salesdocument  <> ''
      INTO @DATA(lv_bsa_so).

    SELECT SINGLE * FROM zbill_ship_add
      WHERE salesdocument = @lv_bsa_so
      INTO @DATA(ls_bsa).

    lt_addr_prt = VALUE #( ( CONV #( ls_bsa-billtostreet  ) ) ( CONV #( ls_bsa-billtostreet1 ) )
                           ( CONV #( ls_bsa-billtostreet2 ) ) ( CONV #( ls_bsa-billtostreet3 ) )
                           ( CONV #( ls_bsa-billtostreet4 ) ) ).
    DELETE lt_addr_prt WHERE table_line IS INITIAL.
    DATA(lv_bsa_bto) = concat_lines_of( table = lt_addr_prt sep = `, ` ).

    lt_addr_prt = VALUE #( ( CONV #( ls_bsa-shiptostreet  ) ) ( CONV #( ls_bsa-shiptostreet1 ) )
                           ( CONV #( ls_bsa-shiptostreet2 ) ) ( CONV #( ls_bsa-shiptostreet3 ) )
                           ( CONV #( ls_bsa-shiptostreet4 ) ) ).
    DELETE lt_addr_prt WHERE table_line IS INITIAL.
    DATA(lv_bsa_sto) = concat_lines_of( table = lt_addr_prt sep = `, ` ).

    DATA(lv_onetime) = xsdbool( hd-distributionchannel = '04' ).

    IF lv_onetime = abap_true.
      SELECT SINGLE FROM zso_onetimecustomer
        FIELDS cityname, postalcode, region, regionname
        WHERE billingdocument = @billingdocument
          AND partnerfunction = 'RE'
        INTO CORRESPONDING FIELDS OF @ls_ot_by.

      SELECT SINGLE FROM zso_onetimecustomer
        FIELDS cityname, postalcode, region, regionname
        WHERE billingdocument = @billingdocument
          AND partnerfunction = 'WE'
        INTO CORRESPONDING FIELDS OF @ls_ot_sh.
    ENDIF.

    " goods go to ship-to address: one-time -> WE record if present, else ship-to partner differs
    DATA(lv_use_ship) = COND abap_bool( WHEN lv_onetime = abap_true AND ls_ot_sh IS NOT INITIAL THEN abap_true
                                        WHEN lv_onetime = abap_true                         THEN abap_false
                                        ELSE lv_ship_diff ).

    " same customer but different ship-to address (ZBILL_SHIP_ADD / one-time WE row)
    DATA(lv_ship_addr_diff) = xsdbool(
         ( lv_bsa_sto IS NOT INITIAL
           AND ls_bsa-shiptoaddressid IS NOT INITIAL
           AND ls_bsa-shiptoaddressid <> ls_bsa-billtoaddressid )
      OR ( ls_ot_sh IS NOT INITIAL
           AND ( ls_ot_sh-cityname   <> ls_ot_by-cityname
              OR ls_ot_sh-postalcode <> ls_ot_by-postalcode
              OR ls_ot_sh-region     <> ls_ot_by-region ) ) ).

    IF lv_ship_addr_diff = abap_true.
      lv_use_ship = abap_true.
    ENDIF.

    IF lv_export = abap_true.
      ls_payload-toGstin     = 'URP'.
      ls_payload-toStateCode = 99.
      ls_payload-toPincode   = 999999.
    ELSEIF ls_by-taxnumber3 IS NOT INITIAL.
      ls_payload-toGstin     = ls_by-taxnumber3.
      ls_payload-toStateCode = CONV i( ls_by-taxnumber3+0(2) ).
    ELSE.
      ls_payload-toGstin     = 'URP'.
      IF lv_onetime = abap_true AND ( ls_ot_by-region IS NOT INITIAL OR ls_ot_by-regionname IS NOT INITIAL ).
        ls_payload-toStateCode = get_state_code( iv_country     = 'IN'
                                                 iv_region      = ls_ot_by-region
                                                 iv_region_name = ls_ot_by-regionname ).
      ELSE.
        ls_payload-toStateCode = get_state_code( iv_country = CONV string( ls_by-country )
                                                 iv_region  = CONV string( ls_by-region ) ).
      ENDIF.
      IF ls_payload-toStateCode = 0.
        rv_payload = |\{"Error":"Unregistered buyer { ls_by-customer } — region { ls_by-region } | &&
                     |could not be mapped to a GST state code"\}|.
        RETURN.
      ENDIF.
    ENDIF.

    IF ls_payload-subSupplyType = '5' AND ls_payload-toGstin <> ls_payload-fromGstin.
      ls_payload-subSupplyType = '8'.
      ls_payload-subSupplyDesc = 'Stock transfer'.
    ENDIF.

    DATA(ls_to) = COND #( WHEN lv_ship_diff = abap_true THEN ls_sh ELSE CORRESPONDING #( ls_by ) ).

    " defaults = customer master (used only when the Z tables have nothing)
    DATA(lv_to_addr)    = |{ ls_to-housenumber } { ls_to-streetname } | &&
                          |{ ls_to-streetprefixname1 } { ls_to-streetprefixname2 } | &&
                          |{ ls_to-streetsuffixname1 } | &&
                          |{ ls_to-districtname } { ls_to-villagename }|.
    DATA(lv_to_city)    = CONV string( ls_to-cityname ).
    DATA(lv_to_pin)     = CONV string( ls_to-postalcode ).
    DATA(lv_to_country) = CONV string( ls_to-country ).
    DATA(lv_to_region)  = CONV string( ls_to-region ).
    DATA lv_to_regname  TYPE string.

    " ZBILL_SHIP_ADD - as printed on tax invoice
    IF lv_use_ship = abap_true AND lv_bsa_sto IS NOT INITIAL.
      lv_to_addr = lv_bsa_sto.
      IF ls_bsa-shiptocity       IS NOT INITIAL. lv_to_city = ls_bsa-shiptocity.       ENDIF.
      IF ls_bsa-shiptopostalcode IS NOT INITIAL. lv_to_pin  = ls_bsa-shiptopostalcode. ENDIF.
      IF ls_bsa-shiptoregion IS NOT INITIAL.
        lv_to_region  = ls_bsa-shiptoregion.
        lv_to_country = COND #( WHEN ls_bsa-shiptocountry IS INITIAL THEN `IN`
                                ELSE CONV string( ls_bsa-shiptocountry ) ).
      ENDIF.
    ELSEIF lv_bsa_bto IS NOT INITIAL.
      lv_to_addr = lv_bsa_bto.
      IF ls_bsa-billtocity       IS NOT INITIAL. lv_to_city = ls_bsa-billtocity.       ENDIF.
      IF ls_bsa-billtopostalcode IS NOT INITIAL. lv_to_pin  = ls_bsa-billtopostalcode. ENDIF.
      IF ls_bsa-billtoregion IS NOT INITIAL.
        lv_to_region  = ls_bsa-billtoregion.
        lv_to_country = COND #( WHEN ls_bsa-billtocountry IS INITIAL THEN `IN`
                                ELSE CONV string( ls_bsa-billtocountry ) ).
      ENDIF.
    ENDIF.

    " one-time customer (channel 04) - ZSO_ONETIMECUSTOMER
    IF lv_onetime = abap_true.
      ls_ot = COND #( WHEN lv_use_ship = abap_true THEN ls_ot_sh ELSE ls_ot_by ).
      IF ls_ot-cityname   IS NOT INITIAL. lv_to_city = ls_ot-cityname.   ENDIF.
      IF ls_ot-postalcode IS NOT INITIAL. lv_to_pin  = ls_ot-postalcode. ENDIF.
      IF ls_ot-region IS NOT INITIAL OR ls_ot-regionname IS NOT INITIAL.
        lv_to_country = 'IN'.
        lv_to_region  = ls_ot-region.
        lv_to_regname = ls_ot-regionname.
      ENDIF.
    ENDIF.

    split_addr( EXPORTING iv_addr  = lv_to_addr
                IMPORTING ev_part1 = ls_payload-toAddr1
                          ev_part2 = ls_payload-toAddr2 ).

    ls_payload-toPlace = clean( iv_text = lv_to_city iv_len = 50 ).

    IF strlen( condense( ls_payload-toAddr1 ) ) < 3.
      ls_payload-toAddr1 = ls_payload-toPlace.
    ENDIF.

    IF strlen( condense( ls_payload-toAddr1 ) ) < 3.
      rv_payload = |\{"Error":"Address missing for customer { ls_to-customer } | &&
                   |— maintain the address in the customer master"\}|.
      RETURN.
    ENDIF.

    IF lv_export = abap_true.
      ls_payload-actToStateCode = ls_payload-fromStateCode.
    ELSE.
      REPLACE ALL OCCURRENCES OF PCRE '[^0-9]' IN lv_to_pin WITH ''.
      ls_payload-toPincode      = COND i( WHEN lv_to_pin IS NOT INITIAL
                                          THEN CONV i( lv_to_pin ) ELSE 0 ).
      ls_payload-actToStateCode = get_state_code( iv_country     = lv_to_country
                                                  iv_region      = lv_to_region
                                                  iv_region_name = lv_to_regname ).

      IF ls_payload-actToStateCode = 0 AND ls_to-taxnumber3 IS NOT INITIAL.
        ls_payload-actToStateCode = CONV i( ls_to-taxnumber3+0(2) ).
      ENDIF.

      IF ls_payload-actToStateCode = 0 AND lv_use_ship = abap_false.
        ls_payload-actToStateCode = ls_payload-toStateCode.
      ENDIF.

      IF ls_payload-actToStateCode = 0.
        rv_payload = |\{"Error":"State not maintained for ship-to customer { ls_to-customer } | &&
                     |— maintain the region in the customer address"\}|.
        RETURN.
      ENDIF.
    ENDIF.

*    IF lv_ship_diff = abap_true AND lv_export = abap_false.
*      ls_payload-transactionType = 2.
*      ls_payload-shipToGSTIN     = ls_sh-taxnumber3.
*      ls_payload-shipToTradeName = clean( CONV string( ls_sh-customername ) ).
*    ELSE.
*      ls_payload-transactionType = 1.
*    ENDIF.
    DATA(lv_ship) = xsdbool( ( lv_ship_diff = abap_true OR lv_ship_addr_diff = abap_true )
                             AND lv_export = abap_false ).

    IF lv_ship = abap_true.
      " ship-to GSTIN only if it belongs to the ship-to state, else URP
      DATA(lv_sh_gstin) = to_upper( condense( CONV string( ls_sh-taxnumber3 ) ) ).
      DATA(lv_act_to_st) = |{ ls_payload-actToStateCode WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
      ls_payload-shipToGSTIN = COND #( WHEN strlen( lv_sh_gstin ) = 15
                                            AND lv_sh_gstin+0(2) = lv_act_to_st
                                       THEN lv_sh_gstin
                                       ELSE `URP` ).
      ls_payload-shipToTradeName = clean( CONV string( ls_sh-customername ) ).
    ENDIF.

    ls_payload-transactionType = COND i( WHEN lv_ship = abap_true AND lv_disp = abap_true THEN 4
                                         WHEN lv_disp = abap_true                         THEN 3
                                         WHEN lv_ship = abap_true                         THEN 2
                                         ELSE 1 ).

    IF hd-billingdocumenttype = 'CBRE' OR lv_f8_return = abap_true.
      DATA(ls_from_tmp) = ls_payload.

      ls_payload-fromGstin        = ls_from_tmp-toGstin.
      ls_payload-fromTrdName      = ls_from_tmp-toTrdName.
      ls_payload-fromAddr1        = ls_from_tmp-toAddr1.
      ls_payload-fromAddr2        = ls_from_tmp-toAddr2.
      ls_payload-fromPlace        = ls_from_tmp-toPlace.
      ls_payload-fromPincode      = ls_from_tmp-toPincode.
      ls_payload-fromStateCode    = ls_from_tmp-toStateCode.
      ls_payload-actFromStateCode = ls_from_tmp-actToStateCode.

      ls_payload-toGstin          = ls_from_tmp-fromGstin.
      ls_payload-toTrdName        = ls_from_tmp-fromTrdName.
      ls_payload-toAddr1          = ls_from_tmp-fromAddr1.
      ls_payload-toAddr2          = ls_from_tmp-fromAddr2.
      ls_payload-toPlace          = ls_from_tmp-fromPlace.
      ls_payload-toPincode        = ls_from_tmp-fromPincode.
      ls_payload-toStateCode      = ls_from_tmp-fromStateCode.
      ls_payload-actToStateCode   = ls_from_tmp-actFromStateCode.

      " dispatch / ship-to belong to the outward flow -> regular transaction
      CLEAR: ls_payload-dispatchFromGSTIN, ls_payload-dispatchFromTradeName,
             ls_payload-shipToGSTIN, ls_payload-shipToTradeName.
      ls_payload-transactionType = 1.
    ENDIF.

    SELECT FROM i_billingdocumentitem AS it
      LEFT OUTER JOIN i_productdescription AS pd
        ON pd~product = it~product AND pd~languageisocode = 'EN'
      LEFT OUTER JOIN i_productplantbasic AS pp
        ON pp~product = it~product AND pp~plant = it~plant
      LEFT OUTER JOIN i_product AS pr
        ON pr~product = it~product
      FIELDS it~billingdocumentitem, it~product, it~billingquantity,
             it~billingquantityunit, it~salesdocumentitemcategory,
             pd~productdescription, pp~consumptiontaxctrlcode, pr~producttype
      WHERE it~billingdocument = @billingdocument
      ORDER BY it~billingdocumentitem
      INTO TABLE @DATA(lt_items).

    SELECT FROM i_billingdocitemprcgelmntbasic
      FIELDS billingdocumentitem, conditiontype, conditionratevalue, conditionamount
      WHERE billingdocument = @billingdocument
        AND conditioninactivereason = ''
      INTO TABLE @DATA(lt_price).

    DATA: lv_price TYPE decfloat34, lv_disc   TYPE decfloat34,
          lv_igst  TYPE decfloat34, lv_cgst   TYPE decfloat34,
          lv_sgst  TYPE decfloat34.

    DATA: lv_oth     TYPE decfloat34,
          lv_frt_tot TYPE decfloat34,
          lv_rndoff  TYPE decfloat34.

    LOOP AT lt_items INTO DATA(it).

      IF it-billingquantity IS INITIAL
         OR it-salesdocumentitemcategory = 'CBLI'
         OR it-producttype = 'DIEN'.
        CONTINUE.
      ENDIF.

      IF it-consumptiontaxctrlcode IS INITIAL.
        rv_payload = |\{"Error":"HSN missing for product { it-product }"\}|.
        RETURN.
      ENDIF.

      CLEAR: ls_item, lv_price, lv_disc, lv_igst, lv_cgst, lv_sgst.

      LOOP AT lt_price INTO DATA(pc) WHERE billingdocumentitem = it-billingdocumentitem.
        CASE pc-conditiontype.
          WHEN 'PPR0' OR 'ZDIS' OR 'PMP0' OR 'ZSCR' OR 'ZFPP' OR 'ZVPR' OR 'ZMUP'.
            lv_price += pc-conditionamount.
          WHEN 'ZK07' OR 'Z022' OR 'Z017'.
            lv_disc += abs( pc-conditionamount ).
          WHEN 'ZSSD'.
            IF hd-distributionchannel = '05'.
              lv_disc += abs( pc-conditionamount ).
            ENDIF.
          WHEN 'YBHD'.
            lv_frt_tot += pc-conditionamount.
          WHEN 'JOIG'.
            lv_igst += pc-conditionamount.
            ls_item-igstRate = pc-conditionratevalue.
          WHEN 'JOCG' OR 'JOIC'.
            lv_cgst += pc-conditionamount.
            ls_item-cgstRate = pc-conditionratevalue.
          WHEN 'JOSG' OR 'JOUG'.
            lv_sgst += pc-conditionamount.
            ls_item-sgstRate = pc-conditionratevalue.
          WHEN 'JTC1' OR 'JTC2'.
            lv_oth += pc-conditionamount.
          WHEN 'DRD1'.
            lv_rndoff += pc-conditionamount.
        ENDCASE.
      ENDLOOP.

      ls_item-productName   = clean( CONV string( it-productdescription ) ).
      ls_item-productDesc   = ls_item-productName.
      ls_item-hsnCode       = CONV int8( it-consumptiontaxctrlcode ).
      ls_item-quantity      = it-billingquantity.
      ls_item-qtyUnit       = map_uqc( CONV string( it-billingquantityunit ) ).

      ls_item-taxableAmount = round( val = ( lv_price - lv_disc ) * lv_rate dec = 2 ).

      IF ls_item-qtyUnit IS INITIAL.
        rv_payload = |\{"Error":"No UQC mapping for unit { it-billingquantityunit } | &&
                     |(product { it-product })"\}|.
        RETURN.
      ENDIF.

      ls_payload-totalValue += ls_item-taxableAmount .
      ls_payload-igstValue  += round( val = lv_igst * lv_rate dec = 2 ).
      ls_payload-cgstValue  += round( val = lv_cgst * lv_rate dec = 2 ).
      ls_payload-sgstValue  += round( val = lv_sgst * lv_rate dec = 2 ).

      APPEND ls_item TO ls_payload-itemList.

    ENDLOOP.

    IF ls_payload-itemList IS INITIAL.
      rv_payload = |\{"Error":"No goods items for E-Way Bill in { billingdocument }"\}|.
      RETURN.
    ENDIF.

    ls_payload-otherValue  = round( val = lv_oth * lv_rate dec = 2 )
                           + COND decfloat34( WHEN lv_frt_tot > 0
                                              THEN round( val = lv_frt_tot * lv_rate dec = 2 ) ELSE 0 ).

    ls_payload-totInvValue = ls_payload-totalValue
                           + ls_payload-igstValue + ls_payload-cgstValue + ls_payload-sgstValue
                           + ls_payload-cessValue + ls_payload-cessNonAdvolValue
                           + ls_payload-otherValue
                           + lv_rndoff.

    DATA(lv_inter) = xsdbool( ls_payload-fromStateCode <> ls_payload-toStateCode ).

    IF lv_inter = abap_true AND ( ls_payload-cgstValue > 0 OR ls_payload-sgstValue > 0 ).
      rv_payload = |\{"Error":"Inter-state supply ({ ls_payload-fromStateCode } to | &&
                   |{ ls_payload-toStateCode }) but the invoice has CGST/SGST | &&
                   |— check tax determination in the billing document"\}|.
      RETURN.
    ENDIF.

    IF lv_inter = abap_false AND ls_payload-igstValue > 0.
      rv_payload = |\{"Error":"Intra-state supply but the invoice has IGST | &&
                   |— check tax determination in the billing document"\}|.
      RETURN.
    ENDIF.

    DATA : lv_trans_id   TYPE string,
           lv_trans_name TYPE string.

    lv_trans_id   = to_upper( condense( CONV string( ls_tr-transportergstin ) ) ).
    lv_trans_name = CONV string( ls_tr-transportername ).

    IF lv_trans_id IS INITIAL AND ls_tr-transporterid IS NOT INITIAL.

      DATA : lv_tid10 TYPE c LENGTH 10,
             lv_bp    TYPE i_businesspartner-businesspartner.

      DATA(lv_tid) = condense( CONV string( ls_tr-transporterid ) ).

      IF strlen( lv_tid ) > 10.

        lv_trans_id = to_upper( lv_tid ).

      ELSE.

        lv_tid10 = lv_tid.
        lv_bp    = |{ lv_tid10 ALPHA = IN }|.

        SELECT SINGLE FROM i_businesspartnertaxnumber
          FIELDS bptaxnumber
          WHERE businesspartner = @lv_bp
            AND bptaxtype       = 'IN3'
          INTO @DATA(lv_bp_gstin).

        IF sy-subrc = 0.
          lv_trans_id = to_upper( condense( CONV string( lv_bp_gstin ) ) ).
        ENDIF.

        IF lv_trans_name IS INITIAL.
          SELECT SINGLE FROM i_supplier
            FIELDS suppliername
            WHERE supplier = @lv_bp
            INTO @DATA(lv_supname).
          lv_trans_name = CONV string( lv_supname ).
        ENDIF.

      ENDIF.

    ENDIF.

    REPLACE ALL OCCURRENCES OF PCRE '[^0-9A-Z]' IN lv_trans_id WITH ''.

    IF strlen( lv_trans_id ) <> 15.
      CLEAR: lv_trans_id, lv_trans_name.
    ENDIF.

    ls_payload-transporterId   = lv_trans_id.
    ls_payload-transporterName = clean( lv_trans_name ).


    DATA(lv_dist) = CONV i( ls_tr-distancekm ).

    IF lv_dist > 4000.
      rv_payload = |\{"Error":"Distance { lv_dist } km exceeds the limit of 4000"\}|.
      RETURN.
    ENDIF.

    ls_payload-transDistance = |{ lv_dist }|.


    DATA(lv_mode) = to_upper( condense( CONV string( ls_tr-modeoftransport ) ) ).
    ls_payload-transMode = SWITCH #( lv_mode
                                     WHEN 'ROAD' THEN '1'
                                     WHEN 'RAIL' THEN '2'
                                     WHEN 'AIR'  THEN '3'
                                     WHEN 'SHIP' THEN '4'
                                     ELSE lv_mode ).

    CASE ls_payload-transMode.

      WHEN '1'.
        IF ls_tr-vehiclenumber IS INITIAL.
          rv_payload = |\{"Error":"Vehicle number is mandatory for Road"\}|.
          RETURN.
        ENDIF.

        ls_payload-vehicleNo = to_upper( CONV string( ls_tr-vehiclenumber ) ).
        REPLACE ALL OCCURRENCES OF PCRE '[\s-]' IN ls_payload-vehicleNo WITH ''.

        IF NOT matches( val  = ls_payload-vehicleNo
                        pcre = '^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$' ).
          rv_payload = |\{"Error":"Vehicle number { ls_payload-vehicleNo } is not in the | &&
                       |required format (e.g. DL01AB1234)"\}|.
          RETURN.
        ENDIF.

        ls_payload-vehicleType = COND #( WHEN ls_tr-vehicletype = 'O' OR ls_tr-vehicletype CS 'ODC'
                                         THEN 'O' ELSE 'R' ).
        ls_payload-transDocNo  = ls_tr-transportdocnumber.

      WHEN '2' OR '3' OR '4'.
        IF ls_tr-transportdocnumber IS INITIAL OR ls_tr-transportdocdate IS INITIAL.
          rv_payload = |\{"Error":"Transport doc no and date are mandatory for Rail / Air / Ship"\}|.
          RETURN.
        ENDIF.
        ls_payload-transDocNo = ls_tr-transportdocnumber.

      WHEN ''.
        IF ls_payload-transporterId IS INITIAL.
          rv_payload = |\{"Error":"Enter mode of transport, or a valid transporter GSTIN | &&
                       |for a Part-A slip"\}|.
          RETURN.
        ENDIF.

      WHEN OTHERS.
        rv_payload = |\{"Error":"Invalid mode of transport { ls_tr-modeoftransport }"\}|.
        RETURN.

    ENDCASE.

    IF ls_payload-transDocNo IS NOT INITIAL AND ls_tr-transportdocdate IS NOT INITIAL.
      ls_payload-transDocDate = |{ ls_tr-transportdocdate+6(2) }/{ ls_tr-transportdocdate+4(2) }/{ ls_tr-transportdocdate(4) }|.
    ENDIF.

    rv_payload = /ui2/cl_json=>serialize(
      data          = ls_payload
      pretty_name   = /ui2/cl_json=>pretty_mode-none
      name_mappings = VALUE #(
        ( abap = 'PLANTDTLS'         json = 'PlantDetails' )
        ( abap = 'PLANT'             json = 'Plant' )
        ( abap = 'ITEMLIST'          json = 'itemList' )
        ( abap = 'PRODUCTNAME'       json = 'productName' )
        ( abap = 'PRODUCTDESC'       json = 'productDesc' )
        ( abap = 'HSNCODE'           json = 'hsnCode' )
        ( abap = 'TAXABLEAMOUNT'     json = 'taxableAmount' )
        ( abap = 'QUANTITY'          json = 'quantity' )
        ( abap = 'QTYUNIT'           json = 'qtyUnit' )
        ( abap = 'IGSTRATE'          json = 'igstRate' )
        ( abap = 'CGSTRATE'          json = 'cgstRate' )
        ( abap = 'SGSTRATE'          json = 'sgstRate' )
        ( abap = 'CESSRATE'          json = 'cessRate' )
        ( abap = 'CESSNONADVOL'      json = 'cessNonAdvol' )
        ( abap = 'SUPPLYTYPE'        json = 'supplyType' )
        ( abap = 'SUBSUPPLYTYPE'     json = 'subSupplyType' )
        ( abap = 'SUBSUPPLYDESC'     json = 'subSupplyDesc' )
        ( abap = 'DOCTYPE'           json = 'docType' )
        ( abap = 'DOCNO'             json = 'docNo' )
        ( abap = 'DOCDATE'           json = 'docDate' )
        ( abap = 'FROMGSTIN'         json = 'fromGstin' )
        ( abap = 'FROMTRDNAME'       json = 'fromTrdName' )
        ( abap = 'FROMADDR1'         json = 'fromAddr1' )
        ( abap = 'FROMADDR2'         json = 'fromAddr2' )
        ( abap = 'FROMPLACE'         json = 'fromPlace' )
        ( abap = 'FROMPINCODE'       json = 'fromPincode' )
        ( abap = 'FROMSTATECODE'     json = 'fromStateCode' )
        ( abap = 'ACTFROMSTATECODE'  json = 'actFromStateCode' )
        ( abap = 'TOGSTIN'           json = 'toGstin' )
        ( abap = 'TOTRDNAME'         json = 'toTrdName' )
        ( abap = 'TOADDR1'           json = 'toAddr1' )
        ( abap = 'TOADDR2'           json = 'toAddr2' )
        ( abap = 'TOPLACE'           json = 'toPlace' )
        ( abap = 'TOPINCODE'         json = 'toPincode' )
        ( abap = 'TOSTATECODE'       json = 'toStateCode' )
        ( abap = 'ACTTOSTATECODE'    json = 'actToStateCode' )
        ( abap = 'TRANSACTIONTYPE'   json = 'transactionType' )
        ( abap = 'DISPATCHFROMGSTIN'     json = 'dispatchFromGSTIN' )
        ( abap = 'DISPATCHFROMTRADENAME' json = 'dispatchFromTradeName' )
        ( abap = 'SHIPTOGSTIN'       json = 'shipToGSTIN' )
        ( abap = 'SHIPTOTRADENAME'   json = 'shipToTradeName' )
        ( abap = 'TOTALVALUE'        json = 'totalValue' )
        ( abap = 'CGSTVALUE'         json = 'cgstValue' )
        ( abap = 'SGSTVALUE'         json = 'sgstValue' )
        ( abap = 'IGSTVALUE'         json = 'igstValue' )
        ( abap = 'CESSVALUE'         json = 'cessValue' )
        ( abap = 'CESSNONADVOLVALUE' json = 'cessNonAdvolValue' )
        ( abap = 'OTHERVALUE'        json = 'otherValue' )
        ( abap = 'TOTINVVALUE'       json = 'totInvValue' )
        ( abap = 'TRANSPORTERID'     json = 'transporterId' )
        ( abap = 'TRANSPORTERNAME'   json = 'transporterName' )
        ( abap = 'TRANSDOCNO'        json = 'transDocNo' )
        ( abap = 'TRANSDOCDATE'      json = 'transDocDate' )
        ( abap = 'TRANSMODE'         json = 'transMode' )
        ( abap = 'TRANSDISTANCE'     json = 'transDistance' )
        ( abap = 'VEHICLENO'         json = 'vehicleNo' )
        ( abap = 'VEHICLETYPE'       json = 'vehicleType' )
        ) ).

    REPLACE ALL OCCURRENCES OF ',"dispatchFromGSTIN":""'     IN rv_payload WITH ''.
    REPLACE ALL OCCURRENCES OF ',"dispatchFromTradeName":""' IN rv_payload WITH ''.
    REPLACE ALL OCCURRENCES OF ',"shipToGSTIN":""'           IN rv_payload WITH ''.
    REPLACE ALL OCCURRENCES OF ',"shipToTradeName":""'       IN rv_payload WITH ''.
    REPLACE ALL OCCURRENCES OF ',"transporterId":""'         IN rv_payload WITH ''.
    REPLACE ALL OCCURRENCES OF ',"transporterName":""'       IN rv_payload WITH ''.
    REPLACE ALL OCCURRENCES OF '"cgstValue":null' IN rv_payload WITH '"cgstValue":0'.
    REPLACE ALL OCCURRENCES OF '"sgstValue":null' IN rv_payload WITH '"sgstValue":0'.
    REPLACE ALL OCCURRENCES OF '"igstValue":null' IN rv_payload WITH '"igstValue":0'.
    REPLACE ALL OCCURRENCES OF '"cgstRate":null'  IN rv_payload WITH '"cgstRate":0'.
    REPLACE ALL OCCURRENCES OF '"sgstRate":null'  IN rv_payload WITH '"sgstRate":0'.
    REPLACE ALL OCCURRENCES OF '"igstRate":null'  IN rv_payload WITH '"igstRate":0'.
    REPLACE ALL OCCURRENCES OF '"cessValue":null'         IN rv_payload WITH '"cessValue":0'.
    REPLACE ALL OCCURRENCES OF '"cessNonAdvolValue":null' IN rv_payload WITH '"cessNonAdvolValue":0'.
    REPLACE ALL OCCURRENCES OF '"cessRate":null'          IN rv_payload WITH '"cessRate":0'.
    REPLACE ALL OCCURRENCES OF '"cessNonAdvol":null'      IN rv_payload WITH '"cessNonAdvol":0'.
    REPLACE ALL OCCURRENCES OF '"otherValue":null'        IN rv_payload WITH '"otherValue":0'.

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

    DATA(lv_payload) =
      zcl_ewaybill_payload=>generate_payload( billingdocument = '0090000001' ).

    out->write( lv_payload ).

  ENDMETHOD.


  METHOD split_addr.
    DATA: lt_w TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lv_w TYPE string,
          lv_b TYPE abap_bool.

    CLEAR: ev_part1, ev_part2.
    DATA(lv_a) = iv_addr.
    CONDENSE lv_a.
    SPLIT lv_a AT space INTO TABLE lt_w.

    LOOP AT lt_w INTO lv_w.
      IF lv_w IS INITIAL. CONTINUE. ENDIF.
      IF lv_b = abap_true OR strlen( ev_part1 ) + strlen( lv_w ) + 1 > 118.
        lv_b = abap_true.
        IF strlen( ev_part2 ) + strlen( lv_w ) + 1 <= 118.
          ev_part2 = COND #( WHEN ev_part2 IS INITIAL THEN lv_w ELSE |{ ev_part2 } { lv_w }| ).
        ENDIF.
      ELSE.
        ev_part1 = COND #( WHEN ev_part1 IS INITIAL THEN lv_w ELSE |{ ev_part1 } { lv_w }| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD clean.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH ''.
    REPLACE ALL OCCURRENCES OF '\' IN rv_text WITH ''.
    REPLACE ALL OCCURRENCES OF PCRE '[\x00-\x1F]' IN rv_text WITH ' '.
    CONDENSE rv_text.
    IF strlen( rv_text ) > iv_len.
      rv_text = rv_text(iv_len).
    ENDIF.
  ENDMETHOD.


  METHOD get_state_code.

    IF iv_country <> 'IN' OR ( iv_region IS INITIAL AND iv_region_name IS INITIAL ).
      RETURN.
    ENDIF.

    DATA lv_name TYPE string.

    IF iv_region IS NOT INITIAL.
      SELECT SINGLE FROM i_regiontext
        FIELDS regionname
        WHERE country  = @iv_country
          AND region   = @iv_region
          AND language = 'E'
        INTO @DATA(lv_rgn_txt).
      lv_name = lv_rgn_txt.
    ENDIF.

    IF lv_name IS INITIAL.
      lv_name = iv_region_name.     " e.g. RegionName from ZSO_ONETIMECUSTOMER
    ENDIF.

    DATA(lv_n) = to_upper( lv_name ).
    REPLACE ALL OCCURRENCES OF PCRE '[^A-Z]' IN lv_n WITH ''.

    IF lv_n IS INITIAL.
      RETURN.
    ENDIF.

    rv_code = COND #(
      WHEN lv_n CS 'JAMMU'                               THEN 1
      WHEN lv_n CS 'HIMACHAL'                            THEN 2
      WHEN lv_n CS 'PUNJAB'                              THEN 3
      WHEN lv_n CS 'CHANDIGARH'                          THEN 4
      WHEN lv_n CS 'UTTARAKHAND' OR lv_n CS 'UTTARANCHAL' THEN 5
      WHEN lv_n CS 'HARYANA'                             THEN 6
      WHEN lv_n CS 'DELHI'                               THEN 7
      WHEN lv_n CS 'RAJASTHAN'                           THEN 8
      WHEN lv_n CS 'UTTARPRADESH'                        THEN 9
      WHEN lv_n CS 'BIHAR'                               THEN 10
      WHEN lv_n CS 'SIKKIM'                              THEN 11
      WHEN lv_n CS 'ARUNACHAL'                           THEN 12
      WHEN lv_n CS 'NAGALAND'                            THEN 13
      WHEN lv_n CS 'MANIPUR'                             THEN 14
      WHEN lv_n CS 'MIZORAM'                             THEN 15
      WHEN lv_n CS 'TRIPURA'                             THEN 16
      WHEN lv_n CS 'MEGHALAYA'                           THEN 17
      WHEN lv_n CS 'ASSAM'                               THEN 18
      WHEN lv_n CS 'BENGAL'                              THEN 19
      WHEN lv_n CS 'JHARKHAND'                           THEN 20
      WHEN lv_n CS 'ODISHA' OR lv_n CS 'ORISSA'          THEN 21
      WHEN lv_n CS 'CHHATTISGARH' OR lv_n CS 'CHATTISGARH' THEN 22
      WHEN lv_n CS 'MADHYAPRADESH'                       THEN 23
      WHEN lv_n CS 'GUJARAT'                             THEN 24
      WHEN lv_n CS 'DAMAN' OR lv_n CS 'DADRA'            THEN 26
      WHEN lv_n CS 'MAHARASHTRA'                         THEN 27
      WHEN lv_n CS 'KARNATAKA'                           THEN 29
      WHEN lv_n CS 'GOA'                                 THEN 30
      WHEN lv_n CS 'LAKSHADWEEP'                         THEN 31
      WHEN lv_n CS 'KERALA'                              THEN 32
      WHEN lv_n CS 'TAMILNADU'                           THEN 33
      WHEN lv_n CS 'PUDUCHERRY' OR lv_n CS 'PONDICHERRY' THEN 34
      WHEN lv_n CS 'ANDAMAN'                             THEN 35
      WHEN lv_n CS 'TELANGANA'                           THEN 36
      WHEN lv_n CS 'ANDHRA'                              THEN 37
      WHEN lv_n CS 'LADAKH'                              THEN 38
      ELSE 0 ).

  ENDMETHOD.


  METHOD map_uqc.
    CASE iv_sap_uom.
      WHEN 'EA' OR 'ST'.  rv_uqc = 'NOS'.
      WHEN 'PC'.          rv_uqc = 'PCS'.
      WHEN 'KG'.          rv_uqc = 'KGS'.
      WHEN 'G'.           rv_uqc = 'GMS'.
      WHEN 'TO'.          rv_uqc = 'TON'.
      WHEN 'CS'.          rv_uqc = 'CTN'.
      WHEN 'QTL'.         rv_uqc = 'QTL'.
      WHEN 'L'.           rv_uqc = 'LTR'.
      WHEN 'ML'.          rv_uqc = 'MLT'.
      WHEN 'KLR'.         rv_uqc = 'KLR'.
      WHEN 'M'.           rv_uqc = 'MTR'.
      WHEN 'KM'.          rv_uqc = 'KME'.
      WHEN 'CM'.          rv_uqc = 'CMS'.
      WHEN 'BKT'.         rv_uqc = 'BKT'.
      WHEN 'M2'.          rv_uqc = 'SQM'.
      WHEN 'FT2'.         rv_uqc = 'SQF'.
      WHEN 'YD2'.         rv_uqc = 'SQY'.
      WHEN 'M3'.          rv_uqc = 'CBM'.
      WHEN 'CM3'.         rv_uqc = 'CCM'.
      WHEN 'DZ'.          rv_uqc = 'DOZ'.
      WHEN 'BOX'.         rv_uqc = 'BOX'.
      WHEN 'CAR' OR 'CT'. rv_uqc = 'CTN'.
      WHEN 'BAG'.         rv_uqc = 'BAG'.
      WHEN 'BT'.          rv_uqc = 'BTL'.
      WHEN 'CAN'.         rv_uqc = 'CAN'.
      WHEN 'DR'.          rv_uqc = 'DRM'.
      WHEN 'ROL'.         rv_uqc = 'ROL'.
      WHEN 'SET'.         rv_uqc = 'SET'.
      WHEN 'PAA'.         rv_uqc = 'PRS'.
      WHEN 'TH'.          rv_uqc = 'THD'.
      WHEN 'TBS'.         rv_uqc = 'TBS'.
      WHEN 'YD'.          rv_uqc = 'YDS'.
      WHEN 'UNT'.         rv_uqc = 'UNT'.
      WHEN OTHERS.        rv_uqc = ''.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
