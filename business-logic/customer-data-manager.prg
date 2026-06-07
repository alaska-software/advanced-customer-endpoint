//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Customer Data Manager - Business logic layer for customer operations
/// </summary>
///
/// <remarks>
/// This class handles all CRUD operations for customer data
/// Uses WAContainer pattern for efficient workarea management
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "dmlb.ch"

CLASS CustomerDataMgr
  PROTECTED:
  CLASS VAR _cPath INIT ".\"
  CLASS VAR _cAlias INIT "CUSTOMER"

  EXPORTED:
  CLASS METHOD setPath( cPath )
  CLASS METHOD getAll()
  CLASS METHOD getById( nId )
  CLASS METHOD getByName( cName )
  CLASS METHOD save( nId, oCustomer )
  CLASS METHOD delete( nId )
  CLASS METHOD initialize( cPath )
ENDCLASS


/// <summary>
/// Initialize data manager with database path
/// </summary>
///
CLASS METHOD CustomerDataMgr:initialize( cPath )
  IF !IsNull(cPath)
    ::_cPath := cPath
  ENDIF
RETURN


/// <summary>
/// Set database path
/// </summary>
///
CLASS METHOD CustomerDataMgr:setPath( cPath )
  ::_cPath := cPath
RETURN


/// <summary>
/// Retrieve all customers
/// </summary>
///
CLASS METHOD CustomerDataMgr:getAll()
  LOCAL oWAC
  LOCAL aCustomers := {}
  LOCAL cStatus

  oWAC := CustomerWAContainer():open( ::_cAlias, @cStatus )

  IF IsNull(oWAC)
    RETURN aCustomers
  ENDIF

  oWAC:pushWorkarea()

  // Iterate through all records
  DbGoTop()
  DO WHILE !Eof()
    AAdd( aCustomers, oWAC:fromWorkarea() )
    DbSkip()
  ENDDO

  oWAC:popWorkarea()
  oWAC:close( @cStatus )

RETURN aCustomers


/// <summary>
/// Retrieve customer by ID
/// </summary>
///
CLASS METHOD CustomerDataMgr:getById( nId )
  LOCAL oWAC
  LOCAL oCustomer := NIL
  LOCAL cStatus
  LOCAL lFound := .F.

  IF IsNull(nId) .OR. nId <= 0
    RETURN NIL
  ENDIF

  oWAC := CustomerWAContainer():open( ::_cAlias, @cStatus )

  IF IsNull(oWAC)
    RETURN NIL
  ENDIF

  oWAC:pushWorkarea()

  // Seek by customer ID
  SET ORDER TO TAG CUST_ID
  lFound := DbSeek( nId )

  IF lFound
    oCustomer := oWAC:fromWorkarea()
  ENDIF

  oWAC:popWorkarea()
  oWAC:close( @cStatus )

RETURN oCustomer


/// <summary>
/// Search customers by name (first or last name)
/// </summary>
///
CLASS METHOD CustomerDataMgr:getByName( cName )
  LOCAL oWAC
  LOCAL aCustomers := {}
  LOCAL cStatus
  LOCAL cSearchName

  IF IsNull(cName) .OR. Empty(cName)
    RETURN aCustomers
  ENDIF

  oWAC := CustomerWAContainer():open( ::_cAlias, @cStatus )

  IF IsNull(oWAC)
    RETURN aCustomers
  ENDIF

  oWAC:pushWorkarea()

  // Convert search name to uppercase for case-insensitive search
  cSearchName := Upper( AllTrim( cName ) )

  // Use NAME index for optimized search
  SET ORDER TO TAG NAME

  // Seek to first matching record
  IF DbSeek( cSearchName, .F. )
    // Collect all matching records
    DO WHILE !Eof() .AND. cSearchName $ Upper( CUSTOMER->LASTNAME + CUSTOMER->FIRSTNAME )
      AAdd( aCustomers, oWAC:fromWorkarea() )
      DbSkip()
    ENDDO
  ELSE
    // If no exact match, scan for partial matches
    DbGoTop()
    DO WHILE !Eof()
      IF cSearchName $ Upper( CUSTOMER->FIRSTNAME ) .OR. ;
         cSearchName $ Upper( CUSTOMER->LASTNAME )
        AAdd( aCustomers, oWAC:fromWorkarea() )
      ENDIF
      DbSkip()
    ENDDO
  ENDIF

  oWAC:popWorkarea()
  oWAC:close( @cStatus )

RETURN aCustomers


/// <summary>
/// Save or update customer
/// </summary>
///
CLASS METHOD CustomerDataMgr:save( nId, oCustomer )
  LOCAL oWAC
  LOCAL lSuccess := .F.
  LOCAL cStatus
  LOCAL lFound := .F.

  IF IsNull(nId) .OR. IsNull(oCustomer)
    RETURN .F.
  ENDIF

  oWAC := CustomerWAContainer():open( ::_cAlias, @cStatus )

  IF IsNull(oWAC)
    RETURN .F.
  ENDIF

  oWAC:pushWorkarea()

  BEGIN SEQUENCE
    // Check if customer exists
    SET ORDER TO TAG CUST_ID
    lFound := DbSeek( nId )

    IF lFound
      // Update existing record
      IF RLock()
        oWAC:toWorkarea( oCustomer )
        CUSTOMER->MODIFIED := Date()
        DbUnlock()
        lSuccess := .T.
      ENDIF
    ELSE
      // Create new record
      IF DbAppend()
        oWAC:toWorkarea( oCustomer )
        CUSTOMER->CUST_ID := nId
        CUSTOMER->CREATED := Date()
        CUSTOMER->MODIFIED := Date()
        CUSTOMER->ACTIVE := .T.
        DbUnlock()
        lSuccess := .T.
      ENDIF
    ENDIF

  RECOVER
    lSuccess := .F.
  END SEQUENCE

  oWAC:popWorkarea()
  oWAC:close( @cStatus )

RETURN lSuccess


/// <summary>
/// Delete customer by ID
/// </summary>
///
CLASS METHOD CustomerDataMgr:delete( nId )
  LOCAL oWAC
  LOCAL lSuccess := .F.
  LOCAL cStatus
  LOCAL lFound := .F.

  IF IsNull(nId) .OR. nId <= 0
    RETURN .F.
  ENDIF

  oWAC := CustomerWAContainer():open( ::_cAlias, @cStatus )

  IF IsNull(oWAC)
    RETURN .F.
  ENDIF

  oWAC:pushWorkarea()

  BEGIN SEQUENCE
    // Seek by customer ID
    SET ORDER TO TAG CUST_ID
    lFound := DbSeek( nId )

    IF lFound
      IF RLock()
        DbDelete()
        DbUnlock()
        lSuccess := .T.
      ENDIF
    ENDIF

  RECOVER
    lSuccess := .F.
  END SEQUENCE

  oWAC:popWorkarea()
  oWAC:close( @cStatus )

RETURN lSuccess


//////////////////////////////////////////////////////////////////////
///
/// CustomerWAContainer - Workarea container for customer table
///
//////////////////////////////////////////////////////////////////////

CLASS CustomerWAContainer FROM WAContainer
  PROTECTED:
  CLASS VAR _Prototype

  EXPORTED:
  CLASS METHOD use()
  METHOD setupPrototype()
  METHOD toWorkarea( oCustomer )
  METHOD fromWorkarea()
ENDCLASS


/// <summary>
/// Open customer table
/// </summary>
///
CLASS METHOD CustomerWAContainer:use()
  LOCAL cDBF := "CUSTOMER"
  LOCAL cPath := CustomerDataMgr():_cPath

  DbeUseArea( .T., "DBFCDX", cPath + cDBF, "CUSTOMER", .T., .F. )

  IF Used()
    // Create indexes if they don't exist
    IF !IndexOrd()
      CreateCustomerIndexes()
    ENDIF
    SET ORDER TO TAG CUST_ID
  ENDIF

RETURN


/// <summary>
/// Setup prototype data object
/// </summary>
///
METHOD CustomerWAContainer:setupPrototype()
  ::_Prototype := DataObject():New( GetCustomerStructure() )
RETURN


/// <summary>
/// Write data object to workarea
/// </summary>
///
METHOD CustomerWAContainer:toWorkarea( oCustomer )
  IF IsNull(oCustomer)
    RETURN .F.
  ENDIF

  // Map object properties to fields
  CUSTOMER->FIRSTNAME := oCustomer:getField("FIRSTNAME")
  CUSTOMER->LASTNAME  := oCustomer:getField("LASTNAME")
  CUSTOMER->EMAIL     := oCustomer:getField("EMAIL")
  CUSTOMER->PHONE     := oCustomer:getField("PHONE")
  CUSTOMER->STREET    := oCustomer:getField("STREET")
  CUSTOMER->CITY      := oCustomer:getField("CITY")
  CUSTOMER->STATE     := oCustomer:getField("STATE")
  CUSTOMER->ZIPCODE   := oCustomer:getField("ZIPCODE")
  CUSTOMER->COUNTRY   := oCustomer:getField("COUNTRY")
  CUSTOMER->NOTES     := oCustomer:getField("NOTES")

  IF ValType(oCustomer:getField("ACTIVE")) == "L"
    CUSTOMER->ACTIVE := oCustomer:getField("ACTIVE")
  ENDIF

RETURN .T.


/// <summary>
/// Read workarea to data object
/// </summary>
///
METHOD CustomerWAContainer:fromWorkarea()
  LOCAL oCustomer := ::createDataObject()

  // Map fields to object properties
  oCustomer:setField( "CUST_ID",    CUSTOMER->CUST_ID )
  oCustomer:setField( "FIRSTNAME",  CUSTOMER->FIRSTNAME )
  oCustomer:setField( "LASTNAME",   CUSTOMER->LASTNAME )
  oCustomer:setField( "EMAIL",      CUSTOMER->EMAIL )
  oCustomer:setField( "PHONE",      CUSTOMER->PHONE )
  oCustomer:setField( "STREET",     CUSTOMER->STREET )
  oCustomer:setField( "CITY",       CUSTOMER->CITY )
  oCustomer:setField( "STATE",      CUSTOMER->STATE )
  oCustomer:setField( "ZIPCODE",    CUSTOMER->ZIPCODE )
  oCustomer:setField( "COUNTRY",    CUSTOMER->COUNTRY )
  oCustomer:setField( "ACTIVE",     CUSTOMER->ACTIVE )
  oCustomer:setField( "CREATED",    CUSTOMER->CREATED )
  oCustomer:setField( "MODIFIED",   CUSTOMER->MODIFIED )
  oCustomer:setField( "NOTES",      CUSTOMER->NOTES )

RETURN oCustomer
