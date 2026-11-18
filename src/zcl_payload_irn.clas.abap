CLASS zcl_payload_irn DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS get_payload
      IMPORTING
        VALUE(billingdocument) TYPE i_billingdocument-billingdocument
      RETURNING
        VALUE(rv_payload)      TYPE string.

    CLASS-METHODS get_credentials
      IMPORTING
        VALUE(billingdocument) TYPE i_billingdocument-billingdocument
      EXPORTING
        ev_gstin               TYPE string
        ev_username            TYPE string
        ev_password            TYPE string.

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

    CLASS-METHODS map_uqc
      IMPORTING iv_sap_uom    TYPE string
      RETURNING VALUE(rv_uqc) TYPE string.

    CLASS-METHODS name_map
      RETURNING VALUE(rt_map) TYPE /ui2/cl_json=>name_mappings.

    CLASS-METHODS get_state_code
      IMPORTING iv_country     TYPE string
                iv_region      TYPE string
                iv_region_name TYPE string OPTIONAL
      RETURNING VALUE(rv_code) TYPE i.
ENDCLASS.



CLASS zcl_payload_irn IMPLEMENTATION.


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


  METHOD get_payload.

    TYPES:
      BEGIN OF ty_attrib_dtls,
        nm  TYPE string,
        val TYPE string,
      END OF ty_attrib_dtls,
      tt_attrib_dtls TYPE STANDARD TABLE OF ty_attrib_dtls WITH EMPTY KEY,

      BEGIN OF ty_bch_dtls,
        nm    TYPE string,
        expdt TYPE string,
        wrdt  TYPE string,
      END OF ty_bch_dtls,

      BEGIN OF ty_item_list,
        slno               TYPE string,
        prddesc            TYPE string,
        isservc            TYPE string,
        hsncd              TYPE string,
        barcde             TYPE string,
        qty                TYPE p LENGTH 13 DECIMALS 3,
        freeqty            TYPE p LENGTH 13 DECIMALS 3,
        unit               TYPE string,
        unitprice          TYPE p LENGTH 13 DECIMALS 3,
        totamt             TYPE p LENGTH 15 DECIMALS 2,
        discount           TYPE p LENGTH 15 DECIMALS 2,
        pretaxval          TYPE p LENGTH 15 DECIMALS 2,
        assamt             TYPE p LENGTH 15 DECIMALS 2,
        gstrt              TYPE p LENGTH 6  DECIMALS 3,
        igstamt            TYPE p LENGTH 15 DECIMALS 2,
        cgstamt            TYPE p LENGTH 15 DECIMALS 2,
        sgstamt            TYPE p LENGTH 15 DECIMALS 2,
        cesrt              TYPE p LENGTH 6  DECIMALS 3,
        cesamt             TYPE p LENGTH 15 DECIMALS 2,
        cesnonadvlamt      TYPE p LENGTH 15 DECIMALS 2,
        statecesrt         TYPE p LENGTH 6  DECIMALS 3,
        statecesamt        TYPE p LENGTH 15 DECIMALS 2,
        statecesnonadvlamt TYPE p LENGTH 15 DECIMALS 2,
        othchrg            TYPE p LENGTH 15 DECIMALS 2,
        totitemval         TYPE p LENGTH 15 DECIMALS 2,
        ordlineref         TYPE string,
        orgcntry           TYPE string,
        prdslno            TYPE string,
        bchdtls            TYPE ty_bch_dtls,
        attribdtls         TYPE tt_attrib_dtls,
      END OF ty_item_list,
      tt_item_list TYPE STANDARD TABLE OF ty_item_list WITH EMPTY KEY,

      BEGIN OF ty_tran_dtls,
        taxsch      TYPE string,
        suptyp      TYPE string,
        regrev      TYPE string,
        ecmgstin    TYPE string,
        igstonintra TYPE string,
      END OF ty_tran_dtls,

      BEGIN OF ty_doc_dtls,
        typ TYPE string,
        no  TYPE string,
        dt  TYPE string,
      END OF ty_doc_dtls,

      BEGIN OF ty_seller_dtls,
        gstin TYPE string,
        lglnm TYPE string,
        trdnm TYPE string,
        addr1 TYPE string,
        addr2 TYPE string,
        loc   TYPE string,
        pin   TYPE i,
        stcd  TYPE string,
        ph    TYPE string,
        em    TYPE string,
      END OF ty_seller_dtls,

      BEGIN OF ty_buyer_dtls,
        gstin TYPE string,
        lglnm TYPE string,
        trdnm TYPE string,
        pos   TYPE string,
        addr1 TYPE string,
        addr2 TYPE string,
        loc   TYPE string,
        pin   TYPE i,
        stcd  TYPE string,
        ph    TYPE string,
        em    TYPE string,
      END OF ty_buyer_dtls,

      BEGIN OF ty_disp_dtls,
        nm    TYPE string,
        addr1 TYPE string,
        addr2 TYPE string,
        loc   TYPE string,
        pin   TYPE i,
        stcd  TYPE string,
      END OF ty_disp_dtls,

      BEGIN OF ty_ship_dtls,
        gstin TYPE string,
        lglnm TYPE string,
        trdnm TYPE string,
        addr1 TYPE string,
        addr2 TYPE string,
        loc   TYPE string,
        pin   TYPE i,
        stcd  TYPE string,
      END OF ty_ship_dtls,

      BEGIN OF ty_val_dtls,
        assval      TYPE p LENGTH 15 DECIMALS 2,
        cgstval     TYPE p LENGTH 15 DECIMALS 2,
        sgstval     TYPE p LENGTH 15 DECIMALS 2,
        igstval     TYPE p LENGTH 15 DECIMALS 2,
        cesval      TYPE p LENGTH 15 DECIMALS 2,
        stcesval    TYPE p LENGTH 15 DECIMALS 2,
        discount    TYPE p LENGTH 15 DECIMALS 2,
        othchrg     TYPE p LENGTH 15 DECIMALS 2,
        rndoffamt   TYPE p LENGTH 15 DECIMALS 2,
        totinvval   TYPE p LENGTH 15 DECIMALS 2,
        totinvvalfc TYPE p LENGTH 15 DECIMALS 2,
      END OF ty_val_dtls,

      BEGIN OF ty_pay_dtls,
        nm       TYPE string,
        accdet   TYPE string,
        mode     TYPE string,
        fininsbr TYPE string,
        payterm  TYPE string,
        payinstr TYPE string,
        crtrn    TYPE string,
        dirdr    TYPE string,
        crday    TYPE i,
        paidamt  TYPE decfloat34,
        paymtdue TYPE decfloat34,
      END OF ty_pay_dtls,

      BEGIN OF ty_doc_perd_dtls,
        invstdt  TYPE string,
        invenddt TYPE string,
      END OF ty_doc_perd_dtls,

      BEGIN OF ty_prec_doc_dtls,
        invno    TYPE string,
        invdt    TYPE string,
        othrefno TYPE string,
      END OF ty_prec_doc_dtls,
      tt_prec_doc_dtls TYPE STANDARD TABLE OF ty_prec_doc_dtls WITH EMPTY KEY,

      BEGIN OF ty_contr_dtls,
        recadvrefr TYPE string,
        recadvdt   TYPE string,
        tendrefr   TYPE string,
        contrrefr  TYPE string,
        extrefr    TYPE string,
        projrefr   TYPE string,
        porefr     TYPE string,
        porefdt    TYPE string,
      END OF ty_contr_dtls,
      tt_contr_dtls TYPE STANDARD TABLE OF ty_contr_dtls WITH EMPTY KEY,

      BEGIN OF ty_ref_dtls,
        invrm       TYPE string,
        docperddtls TYPE ty_doc_perd_dtls,
        precdocdtls TYPE tt_prec_doc_dtls,
        contrdtls   TYPE tt_contr_dtls,
      END OF ty_ref_dtls,

      BEGIN OF ty_addl_doc_dtls,
        url  TYPE string,
        docs TYPE string,
        info TYPE string,
      END OF ty_addl_doc_dtls,
      tt_addl_doc_dtls TYPE STANDARD TABLE OF ty_addl_doc_dtls WITH EMPTY KEY,

      BEGIN OF ty_exp_dtls,
        shipbno TYPE string,
        shipbdt TYPE string,
        port    TYPE string,
        refclm  TYPE string,
        forcur  TYPE string,
        cntcode TYPE string,
        expduty TYPE string,
      END OF ty_exp_dtls,

      BEGIN OF ty_ewb_dtls,
        transid    TYPE string,
        transname  TYPE string,
        distance   TYPE i,
        transdocno TYPE string,
        transdocdt TYPE string,
        vehno      TYPE string,
        vehtype    TYPE string,
        transmode  TYPE string,
      END OF ty_ewb_dtls,

      BEGIN OF ty_plant_dtls,
        plant TYPE string,
      END OF ty_plant_dtls,

      BEGIN OF ty_irn_payload,
        plantdtls   TYPE ty_plant_dtls,     " first node: PlantDetails
        version     TYPE string,
        trandtls    TYPE ty_tran_dtls,
        docdtls     TYPE ty_doc_dtls,
        sellerdtls  TYPE ty_seller_dtls,
        buyerdtls   TYPE ty_buyer_dtls,
        dispdtls    TYPE ty_disp_dtls,
        shipdtls    TYPE ty_ship_dtls,
        itemlist    TYPE tt_item_list,
        valdtls     TYPE ty_val_dtls,
        paydtls     TYPE ty_pay_dtls,
        refdtls     TYPE ty_ref_dtls,
        addldocdtls TYPE tt_addl_doc_dtls,
        expdtls     TYPE ty_exp_dtls,
        ewbdtls     TYPE ty_ewb_dtls,
      END OF ty_irn_payload.

    DATA:
      ls_payload    TYPE ty_irn_payload,
      ls_line       TYPE ty_item_list,
      lv_rndoff     TYPE decfloat34,
      lv_frt_tot    TYPE decfloat34,
      lv_rndoff_tot TYPE decfloat34,
      lv_Dis_tot    TYPE decfloat34,
      lv_oth_tot    TYPE decfloat34,
      lv_totfc      TYPE decfloat34,
      lv_has_ship   TYPE abap_bool,
      lv_has_disp   TYPE abap_bool,
      lv_export     TYPE abap_bool,
      lv_suptyp     TYPE string,
      lv_doctyp     TYPE string.


    SELECT SINGLE FROM i_billingdocument AS h
      FIELDS h~billingdocument, h~billingdocumenttype, h~sddocumentcategory,
             h~billingdocumentdate, h~companycode, h~distributionchannel,
             h~transactioncurrency, h~totaltaxamount,
             h~accountingexchangerate,
             h~billingdocumentiscancelled,
             h~documentreferenceid                                 " ODN
      WHERE h~billingdocument = @billingdocument
      INTO @DATA(hd).

    IF sy-subrc <> 0.
      rv_payload = |\{"Error":"Billing document { billingdocument } not found"\}|.
      RETURN.
    ENDIF.
    IF hd-billingdocumentiscancelled = abap_true.
      rv_payload = |\{"Error":"Billing document is cancelled"\}|.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM i_billingdocumentitem AS i
      FIELDS i~plant, i~companycode
      WHERE i~billingdocument = @billingdocument AND i~plant <> ''
      INTO @DATA(ls_pl).

    ls_payload-plantdtls-plant = ls_pl-plant.

    ls_payload-version = '1.1'.

    DATA(lv_rate) = CONV decfloat34( 1 ).

    IF hd-transactioncurrency <> 'INR'.
      lv_rate = CONV decfloat34( hd-accountingexchangerate ).
      IF lv_rate < 0.
        lv_rate = 1 / abs( lv_rate ).
      ENDIF.
      IF lv_rate = 0.
        rv_payload = |\{"Error":"No exchange rate on billing document for currency | &&
                     |{ hd-transactioncurrency }"\}|.
        RETURN.
      ENDIF.
    ENDIF.

    SELECT SINGLE FROM i_billingdocumentpartner AS bp
      INNER JOIN i_customer AS c ON c~customer = bp~customer
      LEFT OUTER JOIN i_address_2 WITH PRIVILEGED ACCESS AS a ON a~addressid = c~addressid
      LEFT OUTER JOIN i_addressemailaddress_2 WITH PRIVILEGED ACCESS AS d ON d~addressid = a~addressid
      FIELDS c~customer, c~customername, c~taxnumber3, c~country,
             c~cityname, c~postalcode,
             a~housenumber, a~streetname, a~streetprefixname1,
             a~streetprefixname2, a~streetsuffixname1, a~streetsuffixname2,
             a~districtname, a~villagename , c~TelephoneNumber2,d~EmailAddress
      WHERE bp~billingdocument = @billingdocument
        AND bp~partnerfunction = 'RE'
      INTO @DATA(ls_by).

    SELECT SINGLE FROM i_billingdocitempartner AS sp
      INNER JOIN i_customer AS c ON c~customer = sp~customer
      LEFT OUTER JOIN i_address_2 WITH PRIVILEGED ACCESS AS a ON a~addressid = c~addressid
      FIELDS c~customername, c~taxnumber3, c~country, c~cityname, c~postalcode,
             a~housenumber, a~streetname, a~streetprefixname1,
             a~streetprefixname2, a~streetsuffixname1,
             a~districtname, a~villagename
      WHERE sp~billingdocument = @billingdocument
        AND sp~partnerfunction = 'WE'
      INTO @DATA(ls_sh).

    DATA(lv_country) = COND string( WHEN ls_sh-country IS NOT INITIAL
                                    THEN ls_sh-country
                                    ELSE ls_by-country ).
    lv_export = xsdbool( lv_country IS NOT INITIAL AND lv_country <> 'IN' ).

    CASE hd-distributionchannel.
      WHEN '09'.
        lv_export = abap_true.
        lv_suptyp = COND #( WHEN hd-totaltaxamount > 0 THEN 'EXPWP'
                            ELSE                            'EXPWOP' ).
      WHEN '51' OR '52' OR '53'.
        rv_payload = |\{"Error":"DC { hd-distributionchannel } is a UAE channel — | &&
                     |not relevant for Indian e-invoice"\}|.
        RETURN.
      WHEN '05'.
        rv_payload = |\{"Error":"DC 05 Sample / FOC — IRN relevance not confirmed"\}|.
        RETURN.
      WHEN OTHERS.
        lv_suptyp = 'B2B'.

    ENDCASE.

    ls_payload-trandtls = VALUE #(
      igstonintra = 'N'
      regrev      = 'N'
      taxsch      = 'GST'
      suptyp      = lv_suptyp
      ecmgstin    = ''
    ).

    CASE hd-billingdocumenttype.

      WHEN 'F2' OR 'JSN'.
        lv_doctyp = 'INV'.

      WHEN 'G2' OR 'CBRE'.
        lv_doctyp = 'CRN'.

      WHEN 'L2'.
        lv_doctyp = 'DBN'.

      WHEN 'F8'.
        rv_payload = |\{"Error":"Billing type F8 is not e-invoice relevant | &&
                     |— only E-Way Bill applies"\}|.
        RETURN.

      WHEN OTHERS.
        lv_doctyp = 'INV'.

    ENDCASE.

    DATA(lv_docno) = condense( CONV string( hd-documentreferenceid ) ).

    IF lv_docno IS INITIAL OR hd-billingdocumenttype = 'F8'.
      lv_docno = CONV string( hd-billingdocument ).
    ENDIF.

    SHIFT lv_docno LEFT DELETING LEADING '0'.

    ls_payload-docdtls = VALUE #(
      typ = lv_doctyp
      no  = lv_docno
      dt  = |{ hd-billingdocumentdate+6(2) }/{ hd-billingdocumentdate+4(2) }/{ hd-billingdocumentdate(4) }|
    ).

    IF lv_doctyp = 'CRN' OR lv_doctyp = 'DBN'.

      SELECT SINGLE FROM i_billingdocumentitem AS bi
        INNER JOIN i_salesdocumentitem AS si
          ON  si~salesdocument     = bi~salesdocument
          AND si~salesdocumentitem = bi~salesdocumentitem
        INNER JOIN i_billingdocument AS ob
          ON ob~billingdocument = si~referencesddocument
        FIELDS ob~billingdocument, ob~documentreferenceid, ob~billingdocumentdate
        WHERE bi~billingdocument               = @billingdocument
          AND si~referencesddocumentcategory   = 'M'
        INTO @DATA(ls_prec).

      IF sy-subrc = 0.
        DATA(lv_prec_no) = condense( CONV string( ls_prec-documentreferenceid ) ).
        IF lv_prec_no IS INITIAL.
          lv_prec_no = CONV string( ls_prec-billingdocument ).
        ENDIF.
        SHIFT lv_prec_no LEFT DELETING LEADING '0'.

        ls_payload-refdtls-precdocdtls = VALUE #(
          ( invno = lv_prec_no
            invdt = |{ ls_prec-billingdocumentdate+6(2) }/{ ls_prec-billingdocumentdate+4(2) }/{ ls_prec-billingdocumentdate(4) }| ) ).
      ENDIF.

    ENDIF.

    SELECT SINGLE FROM zplant_gst AS p
      FIELDS p~description, p~mobile_no, p~email
      WHERE p~plant = @ls_pl-plant
      INTO @DATA(ls_reg).

    SELECT SINGLE pl~plantname, a~housenumber, a~streetname,
                a~streetprefixname1, a~streetsuffixname1,
                a~districtname, a~cityname, a~postalcode
    FROM i_plant AS pl
    LEFT OUTER JOIN i_address_2 WITH PRIVILEGED ACCESS AS a ON a~addressid = pl~addressid
    WHERE pl~plant = @ls_pl-plant
    INTO @DATA(ls_padr).

    DATA: lv_saddr1 TYPE string,
          lv_saddr2 TYPE string.

    DATA(lv_gstin) = get_seller_gstin( billingdocument ).

    IF lv_gstin IS INITIAL.
      rv_payload = |\{"Error":"Seller GSTIN not found in ZPLANT_GST for plant { ls_pl-plant }"\}|.
      RETURN.
    ENDIF.

    IF NOT matches( val = condense( CONV string( ls_padr-postalcode ) ) pcre = '^[0-9]{6}$' ).
      rv_payload = |\{"Error":"Plant { ls_pl-plant } address has no valid 6-digit pincode"\}|.
      RETURN.
    ENDIF.

    split_addr( EXPORTING iv_addr  = |{ ls_padr-housenumber } { ls_padr-streetname } | &&
                                     |{ ls_padr-streetprefixname1 } { ls_padr-streetsuffixname1 } | &&
                                     |{ ls_padr-districtname }|
                IMPORTING ev_part1 = lv_saddr1
                          ev_part2 = lv_saddr2 ).

    ls_payload-sellerdtls = VALUE #(
      gstin = lv_gstin
      lglnm = clean( iv_text = COND #( WHEN ls_reg-description IS NOT INITIAL
                                       THEN CONV string( ls_reg-description )
                                       ELSE CONV string( ls_padr-plantname ) ) iv_len = 100 )
      trdnm = clean( iv_text = COND #( WHEN ls_reg-description IS NOT INITIAL
                                       THEN CONV string( ls_reg-description )
                                       ELSE CONV string( ls_padr-plantname ) ) iv_len = 100 )
      addr1 = lv_saddr1
      addr2 = lv_saddr2
      loc   = clean( iv_text = CONV string( ls_padr-cityname ) iv_len = 50 )
      pin   = COND i( WHEN ls_padr-postalcode IS NOT INITIAL
                       AND ls_padr-postalcode CO '0123456789 '
                      THEN CONV i( ls_padr-postalcode )
                      ELSE 0 )
      stcd  = substring( val = lv_gstin len = 2 )
      ph    = ls_reg-mobile_no
      em    = ls_reg-email
    ).

    IF lv_export = abap_false.
      DATA(lv_by_gstin) = to_upper( CONV string( ls_by-taxnumber3 ) ).
      REPLACE ALL OCCURRENCES OF PCRE '[^0-9A-Z]' IN lv_by_gstin WITH ``.

      IF lv_by_gstin IS INITIAL.
        rv_payload = |\{"Error":"Customer { ls_by-customer } has no GSTIN — | &&
                     |B2C is not IRN relevant"\}|.
        RETURN.
      ENDIF.

      FIND PCRE '^[0-9]{2}[0-9A-Z]{13}$' IN lv_by_gstin.
      IF sy-subrc <> 0.
        rv_payload = |\{"Error":"Customer { ls_by-customer } GSTIN { lv_by_gstin } | &&
                     |is invalid - must be 15 characters like 07AAAPT1810F1Z4"\}|.
        RETURN.
      ENDIF.

      IF lv_by_gstin = lv_gstin.
        rv_payload = |\{"Error":"Buyer GSTIN equals seller GSTIN { lv_gstin } | &&
                     |— not a supply, IRN not applicable"\}|.
        RETURN.
      ENDIF.

      ls_by-taxnumber3 = lv_by_gstin.

    ENDIF.
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

    IF hd-distributionchannel = '04'.
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

    " buyer : default = customer master, overridden like tax invoice
    DATA(lv_by_addr) = |{ ls_by-housenumber } { ls_by-streetname } | &&
                       |{ ls_by-streetprefixname1 } { ls_by-streetprefixname2 } | &&
                       |{ ls_by-streetsuffixname1 } | &&
                       |{ ls_by-districtname } { ls_by-villagename }|.
    DATA(lv_by_city) = CONV string( ls_by-cityname ).
    DATA(lv_by_pin)  = CONV string( ls_by-postalcode ).

    IF lv_bsa_bto IS NOT INITIAL.
      lv_by_addr = lv_bsa_bto.
      IF ls_bsa-billtocity       IS NOT INITIAL. lv_by_city = ls_bsa-billtocity.       ENDIF.
      IF ls_bsa-billtopostalcode IS NOT INITIAL. lv_by_pin  = ls_bsa-billtopostalcode. ENDIF.
    ENDIF.
    IF ls_ot_by-cityname   IS NOT INITIAL. lv_by_city = ls_ot_by-cityname.   ENDIF.
    IF ls_ot_by-postalcode IS NOT INITIAL. lv_by_pin  = ls_ot_by-postalcode. ENDIF.
    REPLACE ALL OCCURRENCES OF PCRE '[^0-9]' IN lv_by_pin WITH ''.

    DATA: lv_baddr1 TYPE string,
          lv_baddr2 TYPE string.

    split_addr( EXPORTING iv_addr  = lv_by_addr
                IMPORTING ev_part1 = lv_baddr1
                          ev_part2 = lv_baddr2 ).

    ls_payload-buyerdtls = VALUE #(
      gstin = COND #( WHEN lv_export = abap_true THEN 'URP' ELSE ls_by-taxnumber3 )
      lglnm = clean( iv_text = CONV string( ls_by-customername ) iv_len = 100 )
      trdnm = clean( iv_text = CONV string( ls_by-customername ) iv_len = 100 )
      pos   = COND #( WHEN lv_export = abap_true THEN '96' ELSE ls_by-taxnumber3+0(2) )
      addr1 = lv_baddr1
      addr2 = lv_baddr2
      loc   = clean( iv_text = lv_by_city iv_len = 100 )
      pin   = COND i( WHEN lv_export = abap_true THEN 999999
                      WHEN lv_by_pin IS NOT INITIAL THEN CONV i( lv_by_pin )
                      ELSE 0 )
      stcd  = COND #( WHEN lv_export = abap_true THEN '96' ELSE ls_by-taxnumber3+0(2) )
      ph    = ls_by-TelephoneNumber2
      em    = ls_by-EmailAddress
    ).

    DATA(lv_sh_gstin) = to_upper( CONV string( ls_sh-taxnumber3 ) ).
    IF hd-distributionchannel <> '04' AND ls_bsa-shiptogstin IS NOT INITIAL.
      lv_sh_gstin = to_upper( CONV string( ls_bsa-shiptogstin ) ).
    ENDIF.
    REPLACE ALL OCCURRENCES OF PCRE '[^0-9A-Z]' IN lv_sh_gstin WITH ``.
    FIND PCRE '^[0-9]{2}[0-9A-Z]{13}$' IN lv_sh_gstin.
    DATA(lv_sh_valid) = xsdbool( sy-subrc = 0 ).
    ls_sh-taxnumber3 = lv_sh_gstin.

    DATA(lv_addr_diff) = xsdbool(
         ( lv_bsa_sto IS NOT INITIAL
           AND ls_bsa-shiptoaddressid IS NOT INITIAL
           AND ls_bsa-shiptoaddressid <> ls_bsa-billtoaddressid )
      OR ( ls_ot_sh IS NOT INITIAL
           AND ( ls_ot_sh-cityname   <> ls_ot_by-cityname
              OR ls_ot_sh-postalcode <> ls_ot_by-postalcode
              OR ls_ot_sh-region     <> ls_ot_by-region ) ) ).

    IF lv_export = abap_false
       AND ( ( lv_sh_valid = abap_true AND ls_sh-taxnumber3 <> ls_by-taxnumber3 )
          OR lv_addr_diff = abap_true ).

      lv_has_ship = abap_true.

      DATA: lv_haddr1 TYPE string,
            lv_haddr2 TYPE string.
      DATA(lv_sh_addr) = |{ ls_sh-housenumber } { ls_sh-streetname } | &&
                         |{ ls_sh-streetprefixname1 } { ls_sh-streetprefixname2 } | &&
                         |{ ls_sh-streetsuffixname1 } | &&
                         |{ ls_sh-districtname } { ls_sh-villagename }|.
      DATA(lv_sh_city) = CONV string( ls_sh-cityname ).
      DATA(lv_sh_pin)  = CONV string( ls_sh-postalcode ).
      DATA lv_sh_stcd  TYPE i.

      IF lv_bsa_sto IS NOT INITIAL.
        lv_sh_addr = lv_bsa_sto.
        IF ls_bsa-shiptocity       IS NOT INITIAL. lv_sh_city = ls_bsa-shiptocity.       ENDIF.
        IF ls_bsa-shiptopostalcode IS NOT INITIAL. lv_sh_pin  = ls_bsa-shiptopostalcode. ENDIF.
        lv_sh_stcd = get_state_code(
                       iv_country = COND #( WHEN ls_bsa-shiptocountry IS INITIAL THEN `IN`
                                            ELSE CONV string( ls_bsa-shiptocountry ) )
                       iv_region  = CONV string( ls_bsa-shiptoregion ) ).
      ENDIF.
      IF hd-distributionchannel <> '04' AND lv_sh_valid = abap_true.
        lv_sh_stcd = CONV i( lv_sh_gstin+0(2) ).
      ENDIF.
      IF ls_ot_sh-cityname   IS NOT INITIAL. lv_sh_city = ls_ot_sh-cityname.   ENDIF.
      IF ls_ot_sh-postalcode IS NOT INITIAL. lv_sh_pin  = ls_ot_sh-postalcode. ENDIF.
      IF ls_ot_sh-region IS NOT INITIAL OR ls_ot_sh-regionname IS NOT INITIAL.
        lv_sh_stcd = get_state_code( iv_country     = 'IN'
                                     iv_region      = ls_ot_sh-region
                                     iv_region_name = ls_ot_sh-regionname ).
      ENDIF.
      REPLACE ALL OCCURRENCES OF PCRE '[^0-9]' IN lv_sh_pin WITH ''.

      " no state found -> fall back to ship-to GSTIN, then buyer GSTIN
      IF lv_sh_stcd = 0 AND lv_sh_valid = abap_true.
        lv_sh_stcd = CONV i( lv_sh_gstin+0(2) ).
      ENDIF.
      IF lv_sh_stcd = 0.
        lv_sh_stcd = CONV i( ls_by-taxnumber3+0(2) ).
      ENDIF.

      DATA(lv_sh_stcd_c) = |{ lv_sh_stcd WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.

      " GSTIN only if it belongs to the ship-to state, else URP
      DATA(lv_sh_out_gstin) = COND string( WHEN lv_sh_valid = abap_true
                                                AND lv_sh_gstin+0(2) = lv_sh_stcd_c
                                           THEN lv_sh_gstin
                                           ELSE `URP` ).

      split_addr( EXPORTING iv_addr  = lv_sh_addr
                  IMPORTING ev_part1 = lv_haddr1
                            ev_part2 = lv_haddr2 ).

      ls_payload-shipdtls = VALUE #(
        gstin = lv_sh_out_gstin
        lglnm = clean( iv_text = CONV string( ls_sh-customername ) iv_len = 100 )
        trdnm = clean( iv_text = CONV string( ls_sh-customername ) iv_len = 100 )
        addr1 = lv_haddr1
        addr2 = lv_haddr2
        loc   = clean( iv_text = lv_sh_city iv_len = 100 )
        pin   = COND i( WHEN lv_sh_pin IS NOT INITIAL THEN CONV i( lv_sh_pin ) ELSE 0 )
        stcd  = lv_sh_stcd_c
      ).
    ENDIF.

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

        DATA(lv_disp_st) = condense( CONV string( ls_disp-yy1_dispatchstatecode_dlh ) ).
        IF NOT matches( val = lv_disp_st pcre = '^[0-9]{1,2}$' ).
          rv_payload = |\{"Error":"Dispatch state code { lv_disp_st } on delivery { lv_delivery } | &&
                       |must be the 2-digit GST state code (e.g. 29)"\}|.
          RETURN.
        ENDIF.

        DATA(lv_disp_pin) = condense( CONV string( ls_disp-yy1_dispatchpincode_dlh ) ).
        REPLACE ALL OCCURRENCES OF PCRE '[^0-9]' IN lv_disp_pin WITH ''.

        DATA: lv_daddr1 TYPE string,
              lv_daddr2 TYPE string.

        split_addr( EXPORTING iv_addr  = |{ ls_disp-yy1_dispatchadd1_dlh } { ls_disp-yy1_dispatchadd2_dlh }|
                    IMPORTING ev_part1 = lv_daddr1
                              ev_part2 = lv_daddr2 ).

        ls_payload-dispdtls = VALUE #(
          nm    = clean( iv_text = CONV string( ls_disp-yy1_name_dlh ) iv_len = 100 )
          addr1 = lv_daddr1
          addr2 = lv_daddr2
          loc   = clean( iv_text = CONV string( ls_disp-yy1_dispatchareacity_dlh ) iv_len = 100 )
          pin   = COND i( WHEN lv_disp_pin IS NOT INITIAL THEN CONV i( lv_disp_pin ) ELSE 0 )
          stcd  = |{ CONV i( lv_disp_st ) WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
        ).

        IF ls_payload-dispdtls-nm IS INITIAL OR ls_payload-dispdtls-loc IS INITIAL.
          rv_payload = |\{"Error":"Dispatch name or city missing on delivery { lv_delivery }"\}|.
          RETURN.
        ENDIF.

        IF ls_payload-dispdtls-pin < 100000 OR ls_payload-dispdtls-pin > 999999.
          rv_payload = |\{"Error":"Dispatch pincode on delivery { lv_delivery } must be 6 digits"\}|.
          RETURN.
        ENDIF.

        lv_has_disp = abap_true.

      ENDIF.

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
             it~salesdocument, it~salesdocumentitem,
             pd~productdescription, pp~consumptiontaxctrlcode,
             pr~producttype, pr~countryoforigin
      WHERE it~billingdocument = @billingdocument
      ORDER BY it~billingdocumentitem
      INTO TABLE @DATA(lt_items).

    SELECT FROM i_billingdocitemprcgelmntbasic AS pc
      FIELDS pc~billingdocumentitem, pc~conditiontype,
             pc~conditionratevalue, pc~conditionamount
      WHERE pc~billingdocument = @billingdocument
        AND pc~conditioninactivereason = ''
      INTO TABLE @DATA(lt_price).

    LOOP AT lt_items INTO DATA(it).

      CLEAR ls_line.

      IF ( it-billingquantity IS INITIAL AND lv_doctyp = 'INV' )
         OR it-salesdocumentitemcategory = 'CBLI'.
        CONTINUE.
      ENDIF.

      IF it-consumptiontaxctrlcode IS INITIAL.
        rv_payload = |\{"Error":"HSN missing for product { it-product } | &&
                     |(item { it-billingdocumentitem })"\}|.
        RETURN.
      ENDIF.

      DATA: lv_price TYPE decfloat34, lv_disc  TYPE decfloat34,
            lv_oth   TYPE decfloat34, lv_rigst TYPE decfloat34,
            lv_rcgst TYPE decfloat34, lv_rsgst TYPE decfloat34,
            lv_frt   TYPE decfloat34.
      CLEAR: lv_price, lv_disc, lv_oth, lv_rigst, lv_rcgst, lv_rsgst, lv_frt, lv_rndoff.

      LOOP AT lt_price INTO DATA(pc) WHERE billingdocumentitem = it-billingdocumentitem.

        CASE pc-conditiontype.

          WHEN 'PPR0' OR 'ZDIS' OR 'PMP0' OR 'ZSCR' OR 'ZFPP' OR 'ZVPR' OR 'ZMUP'
            OR 'ZCDR'.
            lv_price += pc-conditionamount.

          WHEN 'ZK07' OR 'Z022' OR 'Z017'.
            lv_disc += abs( pc-conditionamount ).

          WHEN 'YBHD'.
            lv_frt += pc-conditionamount.

          WHEN 'JTC1' OR 'JTC2'.
            lv_oth += pc-conditionamount.

          WHEN 'JOIG'.
            ls_line-igstamt += pc-conditionamount.
            lv_rigst         = pc-conditionratevalue.

          WHEN 'JOCG' OR 'JOIC'.
            ls_line-cgstamt += pc-conditionamount.
            lv_rcgst         = pc-conditionratevalue.

          WHEN 'JOSG' OR 'JOUG'.
            ls_line-sgstamt += pc-conditionamount.
            lv_rsgst         = pc-conditionratevalue.

          WHEN 'DRD1'.
            lv_rndoff += pc-conditionamount.

          WHEN OTHERS.

        ENDCASE.

      ENDLOOP.
*      lv_Dis_tot += lv_disc.
      lv_frt_tot    += lv_frt.
      lv_rndoff_tot += lv_rndoff.
      lv_oth_tot    += lv_oth.


      ls_line-unit = map_uqc( CONV string( it-billingquantityunit ) ).
      IF ls_line-unit IS INITIAL AND it-producttype <> 'DIEN'.
        rv_payload = |\{"Error":"No UQC mapping for unit { it-billingquantityunit } | &&
                     |(product { it-product }) — extend map_uqc"\}|.
        RETURN.
      ENDIF.

      ls_line-slno = CONV string( it-billingdocumentitem ).
      SHIFT ls_line-slno LEFT DELETING LEADING '0'.
      ls_line-prddesc = clean( iv_text = CONV string( it-productdescription ) iv_len = 300 ).

      ls_line-isservc = COND #( WHEN it-producttype = 'DIEN' THEN 'Y' ELSE 'N' ).
      ls_line-hsncd   = it-consumptiontaxctrlcode.
      ls_line-qty     = it-billingquantity.

      ls_line-gstrt = COND #( WHEN lv_rigst > 0 THEN lv_rigst ELSE lv_rcgst + lv_rsgst ).

      lv_totfc += lv_price - lv_disc + ls_line-igstamt + ls_line-cgstamt
                + ls_line-sgstamt + ls_line-cesamt + lv_oth + lv_frt.

      ls_line-totamt    = round( val = lv_price          * lv_rate dec = 2 ).
      ls_line-discount  = round( val = lv_disc           * lv_rate dec = 2 ).
      ls_line-othchrg   = 0.   " other charges go only to ValDtls-OthChrg
      ls_line-igstamt   = round( val = ls_line-igstamt   * lv_rate dec = 2 ).
      ls_line-cgstamt   = round( val = ls_line-cgstamt   * lv_rate dec = 2 ).
      ls_line-sgstamt   = round( val = ls_line-sgstamt   * lv_rate dec = 2 ).
      ls_line-cesamt    = round( val = ls_line-cesamt    * lv_rate dec = 2 ).
      ls_line-unitprice = COND #( WHEN it-billingquantity <> 0
                                  THEN round( val = lv_price * lv_rate / it-billingquantity dec = 3 )
                                  ELSE 0 ).

      ls_line-assamt     = ls_line-totamt - ls_line-discount.

      ls_line-totitemval = ls_line-assamt
                         + ls_line-igstamt + ls_line-cgstamt + ls_line-sgstamt
                         + ls_line-cesamt + ls_line-cesnonadvlamt
                         + ls_line-statecesamt + ls_line-statecesnonadvlamt.
*                         + ls_line-othchrg.

      ls_line-ordlineref = |{ it-salesdocument }/{ it-salesdocumentitem }|.
      ls_line-orgcntry   = it-countryoforigin.

      APPEND ls_line TO ls_payload-itemlist.

    ENDLOOP.

    IF ls_payload-itemlist IS INITIAL.
      rv_payload = |\{"Error":"No IRN-relevant items for billing document { billingdocument }"\}|.
      RETURN.
    ENDIF.
    IF lines( ls_payload-itemlist ) > 1000.
      rv_payload = |\{"Error":"{ lines( ls_payload-itemlist ) } items — NIC allows max 1000"\}|.
      RETURN.
    ENDIF.

    CLEAR ls_payload-valdtls.

    DATA lv_items_total TYPE p LENGTH 15 DECIMALS 2.

    LOOP AT ls_payload-itemlist INTO DATA(sm).
      ls_payload-valdtls-assval   += sm-assamt.
      ls_payload-valdtls-cgstval  += sm-cgstamt.
      ls_payload-valdtls-sgstval  += sm-sgstamt.
      ls_payload-valdtls-igstval  += sm-igstamt.
      ls_payload-valdtls-cesval   += sm-cesamt + sm-cesnonadvlamt.
      ls_payload-valdtls-stcesval += sm-statecesamt + sm-statecesnonadvlamt.
      lv_items_total              += sm-totitemval.
    ENDLOOP.

    IF ls_payload-valdtls-igstval + ls_payload-valdtls-cgstval
     + ls_payload-valdtls-sgstval = 0
       AND lv_suptyp <> 'EXPWOP'.
      rv_payload = |\{"Error":"Total GST is zero for billing document { billingdocument } | &&
                   |- IRN cannot be generated. Check tax code / GST conditions."\}|.
      RETURN.
    ENDIF.

    ls_payload-valdtls-discount = abs( lv_frt_tot ).

    ls_payload-valdtls-othchrg  = abs( lv_oth_tot ).

    ls_payload-valdtls-rndoffamt = round( val = lv_rndoff_tot * lv_rate dec = 2 ).

    ls_payload-valdtls-totinvval = lv_items_total
                                 + lv_frt_tot
                                 + ls_payload-valdtls-rndoffamt
                                 + ls_payload-valdtls-othchrg.

    IF hd-transactioncurrency <> 'INR'.
      ls_payload-valdtls-totinvvalfc = round( val = lv_totfc + lv_rndoff dec = 2 ).
    ENDIF.

    IF lv_export = abap_true.
      ls_payload-expdtls = VALUE #(
        refclm  = 'N'
        forcur  = hd-transactioncurrency
        cntcode = lv_country
      ).
    ENDIF.

    DATA(lv_json) = /ui2/cl_json=>serialize(
                  data          = ls_payload
                  pretty_name   = /ui2/cl_json=>pretty_mode-none
                  name_mappings = name_map( ) ).

    IF lv_has_ship = abap_false.
      REPLACE ALL OCCURRENCES OF
        '"ShipDtls":{"Gstin":"","LglNm":"","TrdNm":"","Addr1":"","Addr2":"","Loc":"","Pin":0,"Stcd":""}'
        IN lv_json WITH '"ShipDtls":null'.
    ENDIF.
    IF lv_has_disp = abap_false.
      REPLACE ALL OCCURRENCES OF
        '"DispDtls":{"Nm":"","Addr1":"","Addr2":"","Loc":"","Pin":0,"Stcd":""}'
        IN lv_json WITH '"DispDtls":null'.
    ENDIF.
    REPLACE ALL OCCURRENCES OF PCRE '"PayDtls":\{[^}]*\}' IN lv_json WITH '"PayDtls":null'.
    REPLACE ALL OCCURRENCES OF
      '"RefDtls":{"InvRm":"","DocPerdDtls":{"InvStDt":"","InvEndDt":""},"PrecDocDtls":[],"ContrDtls":[]}'
      IN lv_json WITH '"RefDtls":null'.
    " RefDtls filled (credit / debit note) -> drop its empty sub-nodes
    REPLACE ALL OCCURRENCES OF '"DocPerdDtls":{"InvStDt":"","InvEndDt":""}' IN lv_json WITH '"DocPerdDtls":null'.
    REPLACE ALL OCCURRENCES OF '"ContrDtls":[]' IN lv_json WITH '"ContrDtls":null'.
    REPLACE ALL OCCURRENCES OF '"AddlDocDtls":[]' IN lv_json WITH '"AddlDocDtls":null'.
    REPLACE ALL OCCURRENCES OF
      '"ExpDtls":{"ShipBNo":"","ShipBDt":"","Port":"","RefClm":"","ForCur":"","CntCode":"","ExpDuty":""}'
      IN lv_json WITH '"ExpDtls":null'.
    REPLACE ALL OCCURRENCES OF
      '"EwbDtls":{"TransId":"","TransName":"","Distance":0,"TransDocNo":"","TransDocDt":"","VehNo":"","VehType":"","TransMode":""}'
      IN lv_json WITH '"EwbDtls":null'.
    REPLACE ALL OCCURRENCES OF '"BchDtls":{"Nm":"","ExpDt":"","WrDt":""}' IN lv_json WITH '"BchDtls":null'.
    REPLACE ALL OCCURRENCES OF '"AttribDtls":[]' IN lv_json WITH '"AttribDtls":null'.
    REPLACE ALL OCCURRENCES OF ':""' IN lv_json WITH ':null'.

    rv_payload = lv_json.

  ENDMETHOD.


  METHOD map_uqc.
    CASE iv_sap_uom.
      WHEN 'EA' OR 'ST'.
        rv_uqc = 'NOS'.
      WHEN 'PC'.
        rv_uqc = 'PCS'.
      WHEN 'KG'.
        rv_uqc = 'KGS'.
      WHEN 'G'.
        rv_uqc = 'GMS'.
      WHEN 'TO'.
        rv_uqc = 'TON'.
      WHEN 'QTL'.
        rv_uqc = 'QTL'.
      WHEN 'L'.
        rv_uqc = 'LTR'.
      WHEN 'ML'.
        rv_uqc = 'MLT'.
      WHEN 'KLR'.
        rv_uqc = 'KLR'.
      WHEN 'M'.
        rv_uqc = 'MTR'.
      WHEN 'KM'.
        rv_uqc = 'KME'.
      WHEN 'CM'.
        rv_uqc = 'CMS'.
      WHEN 'M2'.
        rv_uqc = 'SQM'.
      WHEN 'FT2'.
        rv_uqc = 'SQF'.
      WHEN 'YD2'.
        rv_uqc = 'SQY'.
      WHEN 'M3'.
        rv_uqc = 'CBM'.
      WHEN 'CM3'.
        rv_uqc = 'CCM'.
      WHEN 'DZ'.
        rv_uqc = 'DOZ'.
      WHEN 'BOX'.
        rv_uqc = 'BOX'.
      WHEN 'CAR' OR 'CT'.
        rv_uqc = 'CTN'.
      WHEN 'BAG'.
        rv_uqc = 'BAG'.
      WHEN 'BT'.
        rv_uqc = 'BTL'.
      WHEN 'CAN'.
        rv_uqc = 'CAN'.
      WHEN 'DR'.
        rv_uqc = 'DRM'.
      WHEN 'ROL'.
        rv_uqc = 'ROL'.
      WHEN 'SET'.
        rv_uqc = 'SET'.
      WHEN 'PAA'.
        rv_uqc = 'PRS'.
      WHEN 'TH'.
        rv_uqc = 'THD'.
      WHEN 'TBS'.
        rv_uqc = 'TBS'.
      WHEN 'YD'.
        rv_uqc = 'YDS'.
      WHEN 'BKT'.
        rv_uqc = 'BKT'.
      WHEN 'UNT'.
        rv_uqc = 'UNT'.
      WHEN OTHERS.
        rv_uqc = ''.
    ENDCASE.
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
      IF lv_b = abap_true OR strlen( ev_part1 ) + strlen( lv_w ) + 1 > 98.
        lv_b = abap_true.
        IF strlen( ev_part2 ) + strlen( lv_w ) + 1 <= 98.
          ev_part2 = COND #( WHEN ev_part2 IS INITIAL THEN lv_w ELSE |{ ev_part2 } { lv_w }| ).
        ENDIF.
      ELSE.
        ev_part1 = COND #( WHEN ev_part1 IS INITIAL THEN lv_w ELSE |{ ev_part1 } { lv_w }| ).
      ENDIF.
    ENDLOOP.

    IF strlen( ev_part1 ) < 3.
      ev_part1 = 'NA'.
    ENDIF.
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


  METHOD name_map.
    rt_map = VALUE #(
      ( abap = 'PLANTDTLS'          json = 'PlantDetails' )
      ( abap = 'PLANT'              json = 'Plant' )
      ( abap = 'VERSION'            json = 'Version' )
      ( abap = 'TRANDTLS'           json = 'TranDtls' )
      ( abap = 'TAXSCH'             json = 'TaxSch' )
      ( abap = 'SUPTYP'             json = 'SupTyp' )
      ( abap = 'REGREV'             json = 'RegRev' )
      ( abap = 'ECMGSTIN'           json = 'EcmGstin' )
      ( abap = 'IGSTONINTRA'        json = 'IgstOnIntra' )
      ( abap = 'DOCDTLS'            json = 'DocDtls' )
      ( abap = 'TYP'                json = 'Typ' )
      ( abap = 'NO'                 json = 'No' )
      ( abap = 'DT'                 json = 'Dt' )
      ( abap = 'SELLERDTLS'         json = 'SellerDtls' )
      ( abap = 'BUYERDTLS'          json = 'BuyerDtls' )
      ( abap = 'DISPDTLS'           json = 'DispDtls' )
      ( abap = 'SHIPDTLS'           json = 'ShipDtls' )
      ( abap = 'GSTIN'              json = 'Gstin' )
      ( abap = 'LGLNM'              json = 'LglNm' )
      ( abap = 'TRDNM'              json = 'TrdNm' )
      ( abap = 'ADDR1'              json = 'Addr1' )
      ( abap = 'ADDR2'              json = 'Addr2' )
      ( abap = 'LOC'                json = 'Loc' )
      ( abap = 'PIN'                json = 'Pin' )
      ( abap = 'STCD'               json = 'Stcd' )
      ( abap = 'PH'                 json = 'Ph' )
      ( abap = 'EM'                 json = 'Em' )
      ( abap = 'POS'                json = 'Pos' )
      ( abap = 'NM'                 json = 'Nm' )
      ( abap = 'ITEMLIST'           json = 'ItemList' )
      ( abap = 'SLNO'               json = 'SlNo' )
      ( abap = 'PRDDESC'            json = 'PrdDesc' )
      ( abap = 'ISSERVC'            json = 'IsServc' )
      ( abap = 'HSNCD'              json = 'HsnCd' )
      ( abap = 'BARCDE'             json = 'Barcde' )
      ( abap = 'QTY'                json = 'Qty' )
      ( abap = 'FREEQTY'            json = 'FreeQty' )
      ( abap = 'UNIT'               json = 'Unit' )
      ( abap = 'UNITPRICE'          json = 'UnitPrice' )
      ( abap = 'TOTAMT'             json = 'TotAmt' )
      ( abap = 'DISCOUNT'           json = 'Discount' )
      ( abap = 'PRETAXVAL'          json = 'PreTaxVal' )
      ( abap = 'ASSAMT'             json = 'AssAmt' )
      ( abap = 'GSTRT'              json = 'GstRt' )
      ( abap = 'IGSTAMT'            json = 'IgstAmt' )
      ( abap = 'CGSTAMT'            json = 'CgstAmt' )
      ( abap = 'SGSTAMT'            json = 'SgstAmt' )
      ( abap = 'CESRT'              json = 'CesRt' )
      ( abap = 'CESAMT'             json = 'CesAmt' )
      ( abap = 'CESNONADVLAMT'      json = 'CesNonAdvlAmt' )
      ( abap = 'STATECESRT'         json = 'StateCesRt' )
      ( abap = 'STATECESAMT'        json = 'StateCesAmt' )
      ( abap = 'STATECESNONADVLAMT' json = 'StateCesNonAdvlAmt' )
      ( abap = 'OTHCHRG'            json = 'OthChrg' )
      ( abap = 'TOTITEMVAL'         json = 'TotItemVal' )
      ( abap = 'ORDLINEREF'         json = 'OrdLineRef' )
      ( abap = 'ORGCNTRY'           json = 'OrgCntry' )
      ( abap = 'PRDSLNO'            json = 'PrdSlNo' )
      ( abap = 'BCHDTLS'            json = 'BchDtls' )
      ( abap = 'EXPDT'              json = 'ExpDt' )
      ( abap = 'WRDT'               json = 'WrDt' )
      ( abap = 'ATTRIBDTLS'         json = 'AttribDtls' )
      ( abap = 'VAL'                json = 'Val' )
      ( abap = 'VALDTLS'            json = 'ValDtls' )
      ( abap = 'ASSVAL'             json = 'AssVal' )
      ( abap = 'CGSTVAL'            json = 'CgstVal' )
      ( abap = 'SGSTVAL'            json = 'SgstVal' )
      ( abap = 'IGSTVAL'            json = 'IgstVal' )
      ( abap = 'CESVAL'             json = 'CesVal' )
      ( abap = 'STCESVAL'           json = 'StCesVal' )
      ( abap = 'RNDOFFAMT'          json = 'RndOffAmt' )
      ( abap = 'TOTINVVAL'          json = 'TotInvVal' )
      ( abap = 'TOTINVVALFC'        json = 'TotInvValFc' )
      ( abap = 'PAYDTLS'            json = 'PayDtls' )
      ( abap = 'ACCDET'             json = 'AccDet' )
      ( abap = 'MODE'               json = 'Mode' )
      ( abap = 'FININSBR'           json = 'FinInsBr' )
      ( abap = 'PAYTERM'            json = 'PayTerm' )
      ( abap = 'PAYINSTR'           json = 'PayInstr' )
      ( abap = 'CRTRN'              json = 'CrTrn' )
      ( abap = 'DIRDR'              json = 'DirDr' )
      ( abap = 'CRDAY'              json = 'CrDay' )
      ( abap = 'PAIDAMT'            json = 'PaidAmt' )
      ( abap = 'PAYMTDUE'           json = 'PaymtDue' )
      ( abap = 'REFDTLS'            json = 'RefDtls' )
      ( abap = 'INVRM'              json = 'InvRm' )
      ( abap = 'DOCPERDDTLS'        json = 'DocPerdDtls' )
      ( abap = 'INVSTDT'            json = 'InvStDt' )
      ( abap = 'INVENDDT'           json = 'InvEndDt' )
      ( abap = 'PRECDOCDTLS'        json = 'PrecDocDtls' )
      ( abap = 'INVNO'              json = 'InvNo' )
      ( abap = 'INVDT'              json = 'InvDt' )
      ( abap = 'OTHREFNO'           json = 'OthRefNo' )
      ( abap = 'CONTRDTLS'          json = 'ContrDtls' )
      ( abap = 'RECADVREFR'         json = 'RecAdvRefr' )
      ( abap = 'RECADVDT'           json = 'RecAdvDt' )
      ( abap = 'TENDREFR'           json = 'TendRefr' )
      ( abap = 'CONTRREFR'          json = 'ContrRefr' )
      ( abap = 'EXTREFR'            json = 'ExtRefr' )
      ( abap = 'PROJREFR'           json = 'ProjRefr' )
      ( abap = 'POREFR'             json = 'PORefr' )
      ( abap = 'POREFDT'            json = 'PORefDt' )
      ( abap = 'ADDLDOCDTLS'        json = 'AddlDocDtls' )
      ( abap = 'URL'                json = 'Url' )
      ( abap = 'DOCS'               json = 'Docs' )
      ( abap = 'INFO'               json = 'Info' )
      ( abap = 'EXPDTLS'            json = 'ExpDtls' )
      ( abap = 'SHIPBNO'            json = 'ShipBNo' )
      ( abap = 'SHIPBDT'            json = 'ShipBDt' )
      ( abap = 'PORT'               json = 'Port' )
      ( abap = 'REFCLM'             json = 'RefClm' )
      ( abap = 'FORCUR'             json = 'ForCur' )
      ( abap = 'CNTCODE'            json = 'CntCode' )
      ( abap = 'EXPDUTY'            json = 'ExpDuty' )
      ( abap = 'EWBDTLS'            json = 'EwbDtls' )
      ( abap = 'TRANSID'            json = 'TransId' )
      ( abap = 'TRANSNAME'          json = 'TransName' )
      ( abap = 'DISTANCE'           json = 'Distance' )
      ( abap = 'TRANSDOCNO'         json = 'TransDocNo' )
      ( abap = 'TRANSDOCDT'         json = 'TransDocDt' )
      ( abap = 'VEHNO'              json = 'VehNo' )
      ( abap = 'VEHTYPE'            json = 'VehType' )
      ( abap = 'TRANSMODE'          json = 'TransMode' )
    ).
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
      lv_name = iv_region_name.
    ENDIF.

    DATA(lv_n) = to_upper( lv_name ).
    REPLACE ALL OCCURRENCES OF PCRE '[^A-Z]' IN lv_n WITH ''.

    IF lv_n IS INITIAL.
      RETURN.
    ENDIF.

    rv_code = COND #(
      WHEN lv_n CS 'JAMMU'                                 THEN 1
      WHEN lv_n CS 'HIMACHAL'                              THEN 2
      WHEN lv_n CS 'PUNJAB'                                THEN 3
      WHEN lv_n CS 'CHANDIGARH'                            THEN 4
      WHEN lv_n CS 'UTTARAKHAND' OR lv_n CS 'UTTARANCHAL'  THEN 5
      WHEN lv_n CS 'HARYANA'                               THEN 6
      WHEN lv_n CS 'DELHI'                                 THEN 7
      WHEN lv_n CS 'RAJASTHAN'                             THEN 8
      WHEN lv_n CS 'UTTARPRADESH'                          THEN 9
      WHEN lv_n CS 'BIHAR'                                 THEN 10
      WHEN lv_n CS 'SIKKIM'                                THEN 11
      WHEN lv_n CS 'ARUNACHAL'                             THEN 12
      WHEN lv_n CS 'NAGALAND'                              THEN 13
      WHEN lv_n CS 'MANIPUR'                               THEN 14
      WHEN lv_n CS 'MIZORAM'                               THEN 15
      WHEN lv_n CS 'TRIPURA'                               THEN 16
      WHEN lv_n CS 'MEGHALAYA'                             THEN 17
      WHEN lv_n CS 'ASSAM'                                 THEN 18
      WHEN lv_n CS 'BENGAL'                                THEN 19
      WHEN lv_n CS 'JHARKHAND'                             THEN 20
      WHEN lv_n CS 'ODISHA' OR lv_n CS 'ORISSA'            THEN 21
      WHEN lv_n CS 'CHHATTISGARH' OR lv_n CS 'CHATTISGARH' THEN 22
      WHEN lv_n CS 'MADHYAPRADESH'                         THEN 23
      WHEN lv_n CS 'GUJARAT'                               THEN 24
      WHEN lv_n CS 'DAMAN' OR lv_n CS 'DADRA'              THEN 26
      WHEN lv_n CS 'MAHARASHTRA'                           THEN 27
      WHEN lv_n CS 'KARNATAKA'                             THEN 29
      WHEN lv_n CS 'GOA'                                   THEN 30
      WHEN lv_n CS 'LAKSHADWEEP'                           THEN 31
      WHEN lv_n CS 'KERALA'                                THEN 32
      WHEN lv_n CS 'TAMILNADU'                             THEN 33
      WHEN lv_n CS 'PUDUCHERRY' OR lv_n CS 'PONDICHERRY'   THEN 34
      WHEN lv_n CS 'ANDAMAN'                               THEN 35
      WHEN lv_n CS 'TELANGANA'                             THEN 36
      WHEN lv_n CS 'ANDHRA'                                THEN 37
      WHEN lv_n CS 'LADAKH'                                THEN 38
      ELSE 0 ).

  ENDMETHOD.
ENDCLASS.
