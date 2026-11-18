CLASS zcl_ewb_error DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS get_text
      IMPORTING iv_code        TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    CLASS-METHODS get_error_text
      IMPORTING iv_response    TYPE string
      RETURNING VALUE(rv_text) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES: BEGIN OF ty_err,
             code TYPE string,
             text TYPE string,
           END OF ty_err,
           tt_err TYPE SORTED TABLE OF ty_err WITH UNIQUE KEY code.

    CLASS-DATA gt_err TYPE tt_err.

    CLASS-METHODS fill_table.

ENDCLASS.



CLASS ZCL_EWB_ERROR IMPLEMENTATION.


  METHOD get_text.

    IF gt_err IS INITIAL.
      fill_table( ).
    ENDIF.

    DATA(lv_code) = condense( iv_code ).
    SHIFT lv_code LEFT DELETING LEADING '0'.

    READ TABLE gt_err INTO DATA(ls_err) WITH KEY code = lv_code.
    IF sy-subrc = 0.
      rv_text = ls_err-text.
    ELSE.
      rv_text = |Unknown error code { iv_code }|.
    ENDIF.

  ENDMETHOD.


  METHOD get_error_text.

    TYPES: BEGIN OF ty_src,
             error    TYPE string,
             cpierror TYPE string,
             detail   TYPE string,
           END OF ty_src.

    DATA: ls_src   TYPE ty_src,
          lt_codes TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    IF iv_response IS INITIAL.
      rv_text = 'No response from CPI'.
      RETURN.
    ENDIF.

    IF iv_response CS '"Error"' OR iv_response CS '"CpiError"'.
      /ui2/cl_json=>deserialize( EXPORTING json = iv_response
                                 CHANGING  data = ls_src ).
    ENDIF.

    IF ls_src-cpierror IS NOT INITIAL.
      rv_text = |CPI error: { ls_src-cpierror }|.
      IF ls_src-detail IS NOT INITIAL.
        rv_text = |{ rv_text } ({ substring( val = ls_src-detail
                                             len = nmin( val1 = 100
                                                         val2 = strlen( ls_src-detail ) ) ) })|.
      ENDIF.
      RETURN.
    ENDIF.

    IF ls_src-error IS NOT INITIAL.
      rv_text = ls_src-error.
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF PCRE '(?i)"error[a-z_]*"\s*:\s*[\{\[]?\s*"?([0-9,\s]+)'
         IN iv_response
         RESULTS DATA(ls_node).

    IF sy-subrc = 0.

      READ TABLE ls_node-submatches INTO DATA(ls_sub) INDEX 1.
      IF sy-subrc = 0.

        DATA(lv_block) = substring( val = iv_response
                                    off = ls_sub-offset
                                    len = ls_sub-length ).

        FIND ALL OCCURRENCES OF PCRE '\d{3}'
             IN lv_block
             RESULTS DATA(lt_res).

        LOOP AT lt_res INTO DATA(ls_res).

          DATA(lv_code) = substring( val = lv_block
                                     off = ls_res-offset
                                     len = ls_res-length ).

          IF get_text( lv_code ) NS 'Unknown error code'.
            APPEND lv_code TO lt_codes.
          ENDIF.

        ENDLOOP.

      ENDIF.

    ENDIF.

    DELETE ADJACENT DUPLICATES FROM lt_codes.

    LOOP AT lt_codes INTO DATA(lv_c).
      IF rv_text IS INITIAL.
        rv_text = |{ lv_c } : { get_text( lv_c ) }|.
      ELSE.
        rv_text = |{ rv_text }\n{ lv_c } : { get_text( lv_c ) }|.
      ENDIF.
    ENDLOOP.

    IF rv_text IS INITIAL.
      rv_text = iv_response.
    ENDIF.

  ENDMETHOD.


  METHOD fill_table.

    gt_err = VALUE #(
      ( code = '100' text = 'Invalid Json' )
      ( code = '101' text = 'Invalid Username' )
      ( code = '102' text = 'Invalid Password' )
      ( code = '103' text = 'Invalid Client-Id' )
      ( code = '104' text = 'Invalid Client-Id' )
      ( code = '105' text = 'Invalid Token' )
      ( code = '106' text = 'Token Expired' )
      ( code = '107' text = 'Authentication failed. Pls. inform the helpdesk' )
      ( code = '108' text = 'Invalid login credentials' )
      ( code = '109' text = 'Decryption of data failed' )
      ( code = '110' text = 'Invalid Client-ID/Client-Secret' )
      ( code = '111' text = 'GSTIN is not registered to this GSP' )
      ( code = '112' text = 'IMEI does not belong to the user' )
      ( code = '113' text = 'os-type is mandatory in header' )
      ( code = '114' text = 'Invalid os-type parameter value' )
      ( code = '117' text = 'This option is not enabled in Eway Bill 2' )
      ( code = '118' text = 'Try after 5 minutes' )

      ( code = '201' text = 'Invalid Supply Type' )
      ( code = '202' text = 'Invalid Sub-supply Type' )
      ( code = '203' text = 'Sub-transaction type does not belong to transaction type' )
      ( code = '204' text = 'Invalid Document type' )
      ( code = '205' text = 'Document type does not match with transaction & Sub trans type' )
      ( code = '206' text = 'Invalid Invoice Number' )
      ( code = '207' text = 'Invalid Invoice Date' )
      ( code = '208' text = 'Invalid Supplier GSTIN' )
      ( code = '209' text = 'Blank Supplier Address' )
      ( code = '210' text = 'Invalid or Blank Supplier PIN Code' )
      ( code = '211' text = 'Invalid or Blank Supplier state Code' )
      ( code = '212' text = 'Invalid Consignee GSTIN' )
      ( code = '213' text = 'Invalid Consignee Address' )
      ( code = '214' text = 'Invalid Consignee PIN Code' )
      ( code = '215' text = 'Invalid Consignee State Code' )
      ( code = '216' text = 'Invalid HSN Code' )
      ( code = '217' text = 'Invalid UQC Code' )
      ( code = '218' text = 'Invalid Tax Rate for Intra State Transaction' )
      ( code = '219' text = 'Invalid Tax Rate for Inter State Transaction' )
      ( code = '220' text = 'Invalid Trans mode' )
      ( code = '221' text = 'Invalid Approximate Distance' )
      ( code = '222' text = 'Invalid Transporter Id' )
      ( code = '223' text = 'Invalid Transaction Document Number' )
      ( code = '224' text = 'Invalid Transaction Date' )
      ( code = '225' text = 'Invalid Vehicle Number Format' )
      ( code = '226' text = 'Both Transaction and Vehicle Number Blank' )
      ( code = '227' text = 'User Gstin cannot be blank' )
      ( code = '228' text = 'User id cannot be blank' )
      ( code = '229' text = 'Supplier name is required' )
      ( code = '230' text = 'Supplier place is required' )
      ( code = '231' text = 'Consignee name is required' )
      ( code = '232' text = 'Consignee place is required' )
      ( code = '233' text = 'Eway bill does not contain any items' )
      ( code = '234' text = 'Total amount/Taxable amount is mandatory' )
      ( code = '235' text = 'Tax rates for Intra state transaction is blank' )
      ( code = '236' text = 'Tax rates for Inter state transaction is blank' )
      ( code = '237' text = 'Invalid client-Id/client-secret' )
      ( code = '238' text = 'Invalid auth token' )
      ( code = '239' text = 'Invalid action' )
      ( code = '240' text = 'Could not generate eway bill, pls contact helpdesk' )
      ( code = '242' text = 'Invalid or Blank Officer StateCode' )
      ( code = '243' text = 'Invalid or Blank IR Number' )
      ( code = '244' text = 'Invalid or Blank Actual Vehicle Number Format' )
      ( code = '245' text = 'Invalid Verification Date Format' )
      ( code = '246' text = 'Invalid Vehicle Release Date Format' )
      ( code = '247' text = 'Invalid Verification Time Format' )
      ( code = '248' text = 'Invalid Vehicle Release Date Format' )
      ( code = '249' text = 'Actual Value cannot be less than or equal to zero' )
      ( code = '250' text = 'Invalid Vehicle Release Date Format' )
      ( code = '251' text = 'CGST and SGST TaxRate should be same' )
      ( code = '252' text = 'Invalid CGST Tax Rate' )
      ( code = '253' text = 'Invalid SGST Tax Rate' )
      ( code = '254' text = 'Invalid IGST Tax Rate' )
      ( code = '255' text = 'Invalid CESS Rate' )
      ( code = '256' text = 'Invalid Cess Non Advol value' )
      ( code = '278' text = 'User Gstin does not match with Transporter Id' )
      ( code = '280' text = 'Status is not ACTIVE' )
      ( code = '281' text = 'Eway Bill is already expired hence update transporter is not allowed' )
      ( code = '282' text = 'At least 4 digit HSN code is mandatory for taxpayers with turnover less than 5Cr' )
      ( code = '283' text = 'At least 6 digit HSN code is mandatory for taxpayers with turnover 5Cr and above' )

      ( code = '301' text = 'Invalid eway bill number' )
      ( code = '302' text = 'Invalid transporter mode' )
      ( code = '303' text = 'Vehicle number is required' )
      ( code = '304' text = 'Invalid vehicle format' )
      ( code = '305' text = 'Place from is required' )
      ( code = '306' text = 'Invalid from state' )
      ( code = '307' text = 'Invalid reason' )
      ( code = '308' text = 'Invalid remarks' )
      ( code = '309' text = 'Could not update vehicle details, pl contact helpdesk' )
      ( code = '311' text = 'Validity period lapsed, you cannot update vehicle details' )
      ( code = '312' text = 'This eway bill is either not generated by you or cancelled' )
      ( code = '313' text = 'Error in validating ewaybill for vehicle updation' )
      ( code = '315' text = 'Validity period lapsed, you cannot cancel this eway bill' )
      ( code = '316' text = 'Eway bill is already verified, you cannot cancel it' )
      ( code = '317' text = 'Could not cancel eway bill, please contact helpdesk' )
      ( code = '320' text = 'Invalid state to' )
      ( code = '321' text = 'Invalid place to' )
      ( code = '322' text = 'Could not generate consolidated eway bill' )
      ( code = '325' text = 'Could not retrieve data' )
      ( code = '326' text = 'Could not retrieve GSTIN details for the given GSTIN number' )
      ( code = '327' text = 'Could not retrieve data from hsn' )
      ( code = '328' text = 'Could not retrieve transporter details from gstin' )
      ( code = '329' text = 'Could not retrieve States List' )
      ( code = '330' text = 'Could not retrieve UQC list' )
      ( code = '331' text = 'Could not retrieve Error code' )
      ( code = '334' text = 'Could not retrieve user details by userid' )
      ( code = '336' text = 'Could not retrieve transporter data by gstin' )
      ( code = '337' text = 'Could not retrieve HSN details for the given HSN number' )
      ( code = '338' text = 'You cannot update transporter details, as the current transporter has already entered Part B details' )
      ( code = '339' text = 'You are not assigned to update the transporter details of this eway bill' )
      ( code = '341' text = 'This e-way bill is generated by you and hence you cannot reject it' )
      ( code = '342' text = 'You cannot reject this e-way bill as you are not the other party to do so' )
      ( code = '343' text = 'This e-way bill is cancelled' )
      ( code = '344' text = 'Invalid eway bill number' )
      ( code = '345' text = 'Validity period lapsed, you cannot reject the e-way bill' )
      ( code = '346' text = 'You can reject the e-way bill only within 72 hours from generated time' )
      ( code = '347' text = 'Validation of eway bill number failed, while rejecting ewaybill' )
      ( code = '348' text = 'Part-B is not generated for this e-way bill, hence rejection is not allowed' )
      ( code = '350' text = 'Could not generate consolidated eway bill' )
      ( code = '351' text = 'Invalid state code' )
      ( code = '352' text = 'Invalid rfid date' )
      ( code = '353' text = 'Invalid location code' )
      ( code = '354' text = 'Invalid rfid number' )
      ( code = '355' text = 'Invalid Vehicle Number Format' )
      ( code = '356' text = 'Invalid wt on bridge' )
      ( code = '357' text = 'Could not retrieve eway bill details, pl contact helpdesk' )
      ( code = '358' text = 'GSTIN passed in request header is not matching with the user gstin mentioned in payload JSON' )
      ( code = '359' text = 'User GSTIN should match to GSTIN(from) for outward transactions' )
      ( code = '360' text = 'User GSTIN should match to GSTIN(to) for inward transactions' )
      ( code = '361' text = 'Invalid Vehicle Type' )
      ( code = '362' text = 'Transporter document date cannot be earlier than the invoice date' )
      ( code = '363' text = 'E-way bill is not enabled for intra state movement for your state' )
      ( code = '364' text = 'Error in verifying eway bill' )
      ( code = '365' text = 'Error in verifying consolidated eway bill' )
      ( code = '366' text = 'You will not get the ewaybills generated today, however you can access the ewaybills of yesterday' )
      ( code = '367' text = 'Could not retrieve data for officer login' )
      ( code = '368' text = 'Could not update transporter' )
      ( code = '369' text = 'GSTIN/Transin passed in request header should match with the transporter Id mentioned in payload JSON' )
      ( code = '370' text = 'GSTIN/Transin passed in request header should not be the same as supplier(fromGSTIN) or recipient(toGSTIN)' )
      ( code = '371' text = 'Invalid or Blank Supplier Ship-to State Code' )
      ( code = '372' text = 'Invalid or Blank Consignee Ship-to State Code' )
      ( code = '373' text = 'The Supplier ship-to state code should be Other Country for Sub Supply Type Export' )
      ( code = '374' text = 'The Consignee pin code should be 999999 for Sub Supply Type Export' )
      ( code = '375' text = 'The Supplier ship-from state code should be Other Country for Sub Supply Type Import' )
      ( code = '376' text = 'The Supplier pin code should be 999999 for Sub Supply Type Import' )
      ( code = '377' text = 'Sub Supply Type is mentioned as Others, the description for that is mandatory' )
      ( code = '378' text = 'The supplier or consignee belongs to SEZ, Inter state tax rates are applicable here' )
      ( code = '379' text = 'Eway Bill cannot be extended. Already Cancelled' )
      ( code = '380' text = 'Eway Bill cannot be Extended. Not in Active State' )
      ( code = '381' text = 'There is No PART-B/Vehicle Entry. Please Update Vehicle Information' )
      ( code = '382' text = 'You cannot Extend as EWB can be Extended only 8 hours before or after w.r.t Validity of EWB' )
      ( code = '383' text = 'Error While Extending. Please Contact Helpdesk' )
      ( code = '384' text = 'You are not current transporter or Generator of the ewayBill, with no transporter details' )
      ( code = '385' text = 'For Rail/Ship/Air transDocDate is mandatory' )
      ( code = '386' text = 'Reason Code, Remarks is mandatory' )
      ( code = '387' text = 'No Record Found for Entered consolidated eWay bill' )
      ( code = '388' text = 'Exception in regeneration of consolidated eWayBill. Please Contact helpdesk' )
      ( code = '389' text = 'Remaining Distance Required' )
      ( code = '390' text = 'Remaining Distance cannot be greater than Actual Distance' )
      ( code = '391' text = 'No eway bill of specified tripsheet, neither ACTIVE nor not Valid' )
      ( code = '392' text = 'Tripsheet is already cancelled, Hence Regeneration is not possible' )
      ( code = '393' text = 'Invalid GSTIN' )
      ( code = '394' text = 'For other than Road Transport, TransDoc number is required' )
      ( code = '395' text = 'Eway Bill Number should be numeric only' )
      ( code = '396' text = 'Either Eway Bill Number Or Consolidated Eway Bill Number is required for Verification' )
      ( code = '397' text = 'Error in Multi Vehicle Movement Initiation' )
      ( code = '398' text = 'Eway Bill Item List is Empty' )
      ( code = '399' text = 'Unit Code is not matching with any of the Unit Code from ItemList' )

      ( code = '400' text = 'Total quantity is exceeding multi vehicle movement initiation quantity' )
      ( code = '401' text = 'Error in inserting multi vehicle details' )
      ( code = '402' text = 'Total quantity cannot be less than or equal to zero' )
      ( code = '403' text = 'Error in multi vehicle details' )
      ( code = '405' text = 'No record found for multi vehicle update with specified ewbNo groupNo and old vehicleNo/transDocNo with status as ACT' )
      ( code = '406' text = 'Group number cannot be empty or zero' )
      ( code = '407' text = 'Invalid old vehicle number format' )
      ( code = '408' text = 'Invalid new vehicle number format' )
      ( code = '409' text = 'Invalid old transDoc number' )
      ( code = '410' text = 'Invalid new transDoc number' )
      ( code = '411' text = 'Multi Vehicle Initiation data is not there for specified ewayBill and group No' )
      ( code = '412' text = 'Multi Vehicle movement is already Initiated, hence PART B updation not allowed' )
      ( code = '413' text = 'Unit Code is not matching with unit code of first initiation' )
      ( code = '415' text = 'Error in fetching verification data for officer' )
      ( code = '416' text = 'Date range is exceeding allowed date range' )
      ( code = '417' text = 'No verification data found for officer' )
      ( code = '418' text = 'No record found' )
      ( code = '419' text = 'Error in fetching search result for taxpayer/transporter' )
      ( code = '420' text = 'Minimum six characters required for Tradename/legalname search' )
      ( code = '421' text = 'Invalid pincode' )
      ( code = '422' text = 'Invalid mobile number' )
      ( code = '423' text = 'Error in fetching ewaybill list by vehicle number' )
      ( code = '424' text = 'Invalid PAN number' )
      ( code = '425' text = 'Error in fetching Part A data by IR Number' )
      ( code = '426' text = 'For Vehicle Released, vehicle release date and time is mandatory' )
      ( code = '427' text = 'Error in saving Part-A verification Report' )
      ( code = '428' text = 'For Goods Detained, Vehicle Released field is mandatory' )
      ( code = '429' text = 'Error in saving Part-B verification Report' )
      ( code = '430' text = 'Goods Detained Field required' )
      ( code = '431' text = 'Part-A for this ewaybill is already generated by you' )
      ( code = '432' text = 'Invalid vehicle released value' )
      ( code = '433' text = 'Invalid goods detained parameter value' )
      ( code = '434' text = 'Invalid ewbNoAvailable parameter value' )
      ( code = '435' text = 'Part B is already updated, hence updation is not allowed' )
      ( code = '436' text = 'Invalid Consignee ship to State Code for the given pincode' )
      ( code = '437' text = 'Invalid Supplier ship from State Code for the given pincode' )
      ( code = '438' text = 'Invalid Latitude' )
      ( code = '439' text = 'Invalid Longitude' )
      ( code = '440' text = 'Error in inserting in verification data' )
      ( code = '441' text = 'Invalid verification type' )
      ( code = '442' text = 'Error in inserting verification details' )
      ( code = '443' text = 'Invalid invoice available value' )
      ( code = '444' text = 'This eway bill cannot be cancelled as it is generated from NIC1' )
      ( code = '445' text = 'This eway bill cannot be cancelled as it is generated from NIC2' )
      ( code = '446' text = 'Transport details cannot be updated here as it is generated from NIC1' )
      ( code = '447' text = 'Transport details cannot be updated here as it is generated from NIC2' )
      ( code = '448' text = 'Part B cannot be updated as this Ewaybill Part A is generated in NIC1' )
      ( code = '449' text = 'Part B cannot be updated as this Ewaybill Part A is generated in NIC2' )
      ( code = '450' text = 'For outward-export ewaybill, To GSTIN has to be either URP or SEZ' )
      ( code = '451' text = 'For inward-import ewaybill, From GSTIN has to be either URP or SEZ' )
      ( code = '452' text = 'Consolidated Ewaybill cannot be generated as this Ewaybill is generated in NIC2' )
      ( code = '453' text = 'You cannot consolidate ewaybills generated at NIC1 and NIC2 together' )

      ( code = '600' text = 'Invalid category' )
      ( code = '601' text = 'Invalid date format' )
      ( code = '602' text = 'Invalid File Number' )
      ( code = '603' text = 'For file details file number is required' )
      ( code = '604' text = 'E-way bill(s) are already generated for the same document number, you cannot generate again on same document number' )
      ( code = '607' text = 'Dispatch from gstin is mandatory' )
      ( code = '608' text = 'Ship to gstin is mandatory' )
      ( code = '609' text = 'Invalid ship to gstin' )
      ( code = '610' text = 'Invalid dispatch from gstin' )
      ( code = '611' text = 'Invalid document type for the given supply type' )
      ( code = '612' text = 'Invalid transaction type' )
      ( code = '613' text = 'Exception in getting Officer Role' )
      ( code = '614' text = 'Transaction type is mandatory' )
      ( code = '615' text = 'Dispatch From GSTIN cannot be sent as the transaction type selected is Regular' )
      ( code = '616' text = 'Ship to GSTIN cannot be sent as the transaction type selected is Regular' )
      ( code = '617' text = 'Bill-from and dispatch-from gstin should not be same for this transaction type' )
      ( code = '618' text = 'Bill-to and ship-to gstin should not be same for this transaction type' )
      ( code = '619' text = 'Transporter Id is mandatory for generation of Part A slip' )
      ( code = '620' text = 'Total invoice value cannot be less than the sum of total assessable value and tax values' )
      ( code = '621' text = 'Trans mode is mandatory since vehicle number is present' )
      ( code = '622' text = 'Trans mode is mandatory since trans doc number is present' )
      ( code = '623' text = 'IGST value is not applicable for Intra State Transaction' )
      ( code = '624' text = 'SGST/CGST value is not applicable for Inter State Transaction' )
      ( code = '627' text = 'Total value should not be negative' )
      ( code = '628' text = 'Total invoice value should not be negative' )
      ( code = '629' text = 'IGST value should not be negative' )
      ( code = '630' text = 'CGST value should not be negative' )
      ( code = '631' text = 'SGST value should not be negative' )
      ( code = '632' text = 'Cess value should not be negative' )
      ( code = '633' text = 'Cess non advol should not be negative' )
      ( code = '634' text = 'Vehicle type should not be ODC when transmode is other than road' )
      ( code = '635' text = 'You cannot update part B, as the current transporter has already entered Part B details' )
      ( code = '636' text = 'You are not assigned to update part B' )
      ( code = '637' text = 'You cannot extend ewaybill, as the current transporter has already entered Part B details' )
      ( code = '638' text = 'Transport mode is mandatory as Vehicle Number/Transport Document Number is given' )
      ( code = '640' text = 'Total Invoice Value is mandatory' )
      ( code = '641' text = 'For outward CKD/SKD/Lots supply type, Bill To state should be Other Country, since the Bill To GSTIN given is of SEZ unit' )
      ( code = '642' text = 'For inward CKD/SKD/Lots supply type, Bill From state should be Other Country, since the Bill From GSTIN given is of SEZ unit' )
      ( code = '643' text = 'For regular transaction, Bill from state code and Dispatch from state code should be same' )
      ( code = '644' text = 'For regular transaction, Bill to state code and Ship to state code should be same' )
      ( code = '645' text = 'You cannot do Multi Vehicle movement, as current transporter already entered part B' )
      ( code = '646' text = 'You are not assigned to do multi vehicle movement' )
      ( code = '647' text = 'Could not insert RFID data, pl contact helpdesk' )
      ( code = '648' text = 'Multi Vehicle movement is already Initiated, hence generation of consolidated eway bill is not allowed' )
      ( code = '649' text = 'You cannot generate consolidated eway bill, as the current transporter has already entered Part B details' )
      ( code = '650' text = 'You are not assigned to generate consolidated ewaybill' )
      ( code = '651' text = 'For Category Part-A or Part-B ewbdt is mandatory' )
      ( code = '652' text = 'For Category EWB03 procdt is mandatory' )
      ( code = '654' text = 'This GSTIN has generated a common Enrolment Number. Hence you are not allowed to generate Eway bill' )
      ( code = '655' text = 'This GSTIN has generated a common Enrolment Number. Hence you cannot mention it as a transporter' )
      ( code = '656' text = 'This Eway Bill does not belong to your state' )
      ( code = '657' text = 'Eway Bill Category wise details will be available after 4 days only' )
      ( code = '658' text = 'You are blocked from accessing this API as the allowed number of requests has been exceeded for this duration' )
      ( code = '659' text = 'Remarks is mandatory' )
      ( code = '670' text = 'Invalid Month Parameter' )
      ( code = '671' text = 'Invalid Year Parameter' )
      ( code = '672' text = 'User Id is mandatory' )
      ( code = '673' text = 'Error in getting officer dashboard' )
      ( code = '675' text = 'Error in getting EWB03 details by acknowledgement date range' )
      ( code = '676' text = 'Error in getting EWB Not Available List by entered date range' )
      ( code = '677' text = 'Error in getting EWB Not Available List by closed date range' )
      ( code = '678' text = 'Invalid Uniq No' )
      ( code = '679' text = 'Invalid EWB03 Ack No' )
      ( code = '680' text = 'Invalid Close Reason' )
      ( code = '681' text = 'Error in Closing EWB Verification Data' )
      ( code = '682' text = 'No Record available to Close' )
      ( code = '683' text = 'Error in fetching WatchList Data' )
      ( code = '685' text = 'Exception in fetching dashboard data' )

      ( code = '700' text = 'You are not assigned to extend e-waybill' )
      ( code = '701' text = 'Invalid Vehicle Direction' )
      ( code = '702' text = 'The distance between the pincodes given is too high' )
      ( code = '703' text = 'Since the consignor is Composite Taxpayer, inter state transactions are not allowed' )
      ( code = '704' text = 'Since the consignor is Composite Taxpayer, Tax rates should be zero' )
      ( code = '705' text = 'Invalid transit type' )
      ( code = '706' text = 'Address Line1 is mandatory' )
      ( code = '707' text = 'Address Line2 is mandatory' )
      ( code = '708' text = 'Address Line3 is mandatory' )
      ( code = '709' text = 'Pin to pin distance is not available for the given pin codes' )
      ( code = '710' text = 'Invalid state code for the given pincode' )
      ( code = '711' text = 'Invalid value for isInTransit field' )
      ( code = '712' text = 'Transit Type is not required as the goods are not in movement' )
      ( code = '713' text = 'Transit Address is not required as the goods are not in movement' )
      ( code = '714' text = 'Document type - Tax Invoice is not allowed for composite tax payer' )
      ( code = '715' text = 'The Consignor GSTIN is blocked from e-waybill generation as Return is not filed for past 2 months' )
      ( code = '716' text = 'The Consignee GSTIN is blocked from e-waybill generation as Return is not filed for past 2 months' )
      ( code = '717' text = 'The Transporter GSTIN is blocked from e-waybill generation as Return is not filed for past 2 months' )
      ( code = '718' text = 'The User GSTIN is blocked from Transporter Updation as Return is not filed for past 2 months' )
      ( code = '719' text = 'The Transporter GSTIN is blocked from Transporter Updation as Return is not filed for past 2 months' )
      ( code = '720' text = 'E-Way Bill should be generated as part of IRN generation or with reference to IRN in E Invoice System, since Supplier is enabled for E Invoice' )
      ( code = '721' text = 'The distance between the given pincodes is not available in the system. Please provide distance' )
      ( code = '722' text = 'Consignee GSTIN is cancelled and document date is later than the De-Registration date' )
      ( code = '724' text = 'HSN code of at least one item should be of goods to generate e-Way Bill' )
      ( code = '726' text = 'Vehicle type cannot be regular when transportation mode is ship' )
      ( code = '727' text = 'For Ship Transport, either vehicle number or transport document number is required' )
      ( code = '728' text = 'You can cancel the ewaybill within 24 hours from Part B entry' )
      ( code = '729' text = 'TransDoc date is required for transport mode Ship as the transport document number is provided' )

      ( code = '801' text = 'Transporter id should not be given for Gold e-Waybill' )
      ( code = '802' text = 'Transporter name should not be given for Gold e-Waybill' )
      ( code = '803' text = 'Transport document number should not be given for Gold e-Waybill' )
      ( code = '804' text = 'Transport document date should not be given for Gold e-Waybill' )
      ( code = '805' text = 'Vehicle number should not be given for Gold e-Waybill' )
      ( code = '806' text = 'Vehicle Type should not be given for Gold e-Waybill' )
      ( code = '807' text = 'Transportation mode is mandatory for Gold e-Waybill' )
      ( code = '808' text = 'Inter-State ewaybill is not allowed for gold' )
      ( code = '809' text = 'Other items are not allowed with Gold e-Waybill' )
      ( code = '810' text = 'Transporter cannot be updated for Gold e-Waybill' )
      ( code = '811' text = 'Vehicle cannot be updated for Gold e-Waybill' )
      ( code = '812' text = 'Consolidated e-Waybill cannot be generated for Gold e-Waybill' )
      ( code = '813' text = 'Duplicate request at the same time' )
      ( code = '814' text = 'Multi Vehicle Movement cannot be initiated for Gold e-Waybill' )
      ( code = '815' text = 'Transportation mode should be road for Gold e-Waybill' )
      ( code = '816' text = 'Transportation mode should be road for extending Gold e-Waybill' )
      ( code = '817' text = 'MultiVehicleMovement cannot be initiated. Eway Bill is not in Active State' )
      ( code = '818' text = 'Validity period lapsed. Cannot generate consolidated Eway Bill' )
      ( code = '819' text = 'Ewaybill cannot be generated for the document date which is prior to 01/07/2017' )
      ( code = '820' text = 'You cannot generate e-Waybill with document date earlier than 180 days' )
      ( code = '821' text = 'e-Waybill cannot be extended as the allowed limit is 360 days' )
      ( code = '823' text = 'Invalid RR No' )
      ( code = '855' text = 'Supplier GSTIN could not be TDS or TCS' )
    ).

  ENDMETHOD.
ENDCLASS.
