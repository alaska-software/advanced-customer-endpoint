//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Customer Data Manager - Business logic layer for customer operations
/// </summary>
///
/// <remarks>
/// This class handles all CRUD operations for customer data.
/// Uses the WAContainer pattern for efficient, stateless workarea
/// management.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "dmlb.ch"


/// <summary>
/// Evaluates the current index key expression and returns its value
/// </summary>
///
/// <returns>Value: Current index key value for the active order</returns>
///
FUNCTION OrdKeyVal()
RETURN &(OrdKey())


CLASS CustomerDataMgr
  EXPORTED:
  CLASS METHOD getAll()
  CLASS METHOD getById( cId )
  CLASS METHOD getByName( cName )
  CLASS METHOD getByEmail( cEmail )
  CLASS METHOD getByCity( cCity )
  CLASS METHOD getActive()
  CLASS METHOD update( cId, oCustomer )
  CLASS METHOD add( oCustomer )
  CLASS METHOD addWithId()
  CLASS METHOD delete( cId )
ENDCLASS


/// <summary>
/// Returns an array of all customer records (not deleted).
/// Uses the cust_id index for ordered traversal.
/// </summary>
///
/// <returns>Array: All customer records ordered by cust_id, or NIL on open failure</returns>
///
CLASS METHOD CustomerDataMgr:getAll()
  LOCAL oWAC, oEntry, aRet

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN nil
  ENDIF

  OrdSetFocus("cust_id")
  DbGoTop()

  aRet := {}
  DO WHILE !Eof()
    oEntry := oWAC:fromWorkarea()
    AAdd( aRet, oEntry )
    DbSkip(1)
  ENDDO

  oWAC:close()
RETURN aRet


/// <summary>
/// Returns a single customer record matching the given cust_id.
/// Uses the cust_id TAG (plain field value, no transformation).
/// </summary>
///
/// <param name="cId">Customer ID to search for</param>
/// <returns>Object: Matching customer record, or NIL if not found or on open failure</returns>
///
CLASS METHOD CustomerDataMgr:getById( cId )
  LOCAL oWAC, oEntry

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN nil
  ENDIF

  OrdSetFocus("cust_id")
  IF !DbSeek( cId )
    oWAC:close()
    RETURN nil
  ENDIF

  oEntry := oWAC:fromWorkarea()
  oWAC:close()
RETURN oEntry


/// <summary>
/// Returns an array of customer records matching the given name fragment.
/// Index key expression: Upper( lastname + firstname )
/// cName is uppercased internally before seeking.
/// </summary>
///
/// <param name="cName">Name fragment to search for (uppercased internally)</param>
/// <returns>Array: Matching customer records, empty array if none found, or NIL on open failure</returns>
///
CLASS METHOD CustomerDataMgr:getByName( cName )
  LOCAL oWAC, oEntry, aRet, cSeekVal

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN nil
  ENDIF

  cSeekVal := Upper( cName )

  OrdSetFocus("name")
  IF !DbSeek( cSeekVal )
    oWAC:close()
    RETURN {}
  ENDIF

  aRet := {}
  DO WHILE OrdKeyVal() = cSeekVal .AND. !Eof()
    oEntry := oWAC:fromWorkarea()
    AAdd( aRet, oEntry )
    DbSkip(1)
  ENDDO

  oWAC:close()
RETURN aRet


/// <summary>
/// Returns a single customer record matching the given email address.
/// Index key expression: Upper( email )
/// </summary>
///
/// <param name="cEmail">Email address to search for (uppercased internally)</param>
/// <returns>Object: Matching customer record, or NIL if not found or on open failure</returns>
///
CLASS METHOD CustomerDataMgr:getByEmail( cEmail )
  LOCAL oWAC, oEntry, cSeekVal

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN nil
  ENDIF

  cSeekVal := Upper( cEmail )

  OrdSetFocus("email")
  IF !DbSeek( cSeekVal )
    oWAC:close()
    RETURN nil
  ENDIF

  oEntry := oWAC:fromWorkarea()
  oWAC:close()
RETURN oEntry


/// <summary>
/// Returns an array of customer records located in the given city.
/// Index key expression: Upper( city )
/// </summary>
///
/// <param name="cCity">City name to search for (uppercased internally)</param>
/// <returns>Array: Matching customer records, empty array if none found, or NIL on open failure</returns>
///
CLASS METHOD CustomerDataMgr:getByCity( cCity )
  LOCAL oWAC, oEntry, aRet, cSeekVal

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN nil
  ENDIF

  cSeekVal := Upper( cCity )

  OrdSetFocus("city")
  IF !DbSeek( cSeekVal )
    oWAC:close()
    RETURN {}
  ENDIF

  aRet := {}
  DO WHILE OrdKeyVal() = cSeekVal .AND. !Eof()
    oEntry := oWAC:fromWorkarea()
    AAdd( aRet, oEntry )
    DbSkip(1)
  ENDDO

  oWAC:close()
RETURN aRet


/// <summary>
/// Returns an array of all active customer records.
/// Index key expression: active (logical field)
/// Seeks .T. to find all active customers.
/// </summary>
///
/// <returns>Array: All active customer records, empty array if none found, or NIL on open failure</returns>
///
CLASS METHOD CustomerDataMgr:getActive()
  LOCAL oWAC, oEntry, aRet

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN nil
  ENDIF

  OrdSetFocus("active")
  IF !DbSeek( .T. )
    oWAC:close()
    RETURN {}
  ENDIF

  aRet := {}
  DO WHILE OrdKeyVal() == .T. .AND. !Eof()
    oEntry := oWAC:fromWorkarea()
    AAdd( aRet, oEntry )
    DbSkip(1)
  ENDDO

  oWAC:close()
RETURN aRet


/// <summary>
/// Updates an existing customer record identified by cust_id.
/// Locks the record, writes the new data, then unlocks.
/// Does NOT touch created or modified fields (maintained by WAC).
/// </summary>
///
/// <param name="cId">Customer ID of the record to update</param>
/// <param name="oCustomer">Customer object containing the updated field values</param>
/// <returns>Logical: .T. if updated successfully, .F. if not found, locked, or on open failure</returns>
///
CLASS METHOD CustomerDataMgr:update( cId, oCustomer )
  LOCAL oWAC

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN .F.
  ENDIF

  OrdSetFocus("cust_id")
  IF !DbSeek( cId )
    oWAC:close()
    RETURN .F.
  ENDIF

  IF oWAC:tryRecordLock()
    oCustomer:cust_id := cId  // ensure ID is not changed during update
    oWAC:toWorkarea( oCustomer )
    DbCommit()
    oWAC:doRecordUnlock()
  ELSE
    oWAC:close()
    RETURN .F.
  ENDIF

  oWAC:close()
RETURN .T.


/// <summary>
/// Appends a new customer record with a synthetic cust_id.
/// The ID is derived from the first 4 characters of lastname+city (uppercased)
/// followed by the current record number zero-padded to 4 digits.
/// Delegates the actual write to addWithId(). oCustomer is updated
/// in-place with the saved record on success.
/// created and modified are maintained by WAC - not set here.
/// </summary>
///
/// <param name="oCustomer">Customer object with all fields except cust_id (generated here)</param>
/// <returns>Logical: .T. if appended successfully, .F. on failure</returns>
///
CLASS METHOD CustomerDataMgr:add( oCustomer )
  LOCAL lRet
  LOCAL nRecCnt
  LOCAL oWAC

  // just fake a syntetic customer id if not given
  IF Empty( oCustomer:cust_id )
    oWAC := wacCustomer():open()
    IF IsNull(oWAC)
      RETURN .F.
    ENDIF
    nRecCnt := LastRec()+1
    oWAC:close()
    oCustomer:cust_id   := Upper( Left( oCustomer:lastname-oCustomer:city , 4 ) ) + StrZero( nRecCnt, 4 )
  ENDIF

  lRet := ::addWithId( @oCustomer )
RETURN lRet


/// <summary>
/// Appends a new customer record using the cust_id already present on oCustomer.
/// Copies all customer fields explicitly, writes to workarea, and commits.
/// oCustomer is refreshed in-place from the saved record on success.
/// A duplicate cust_id check is performed.
/// </summary>
///
/// <param name="oCustomer">Customer object with all fields including cust_id set</param>
/// <returns>Logical: .T. if appended successfully, .F. on open failure</returns>
///
CLASS METHOD CustomerDataMgr:addWithId( oCustomer )
  LOCAL oWAC, oE

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN .F.
  ENDIF

  OrdSetFocus("cust_id")
  IF DbSeek( oCustomer:cust_id )
    oWAC:close()
    RETURN .F.
  ENDIF

  DbAppend()
  oE := oWAC:getDefault()

  oE:cust_id   := oCustomer:cust_id
  oE:firstname := oCustomer:firstname
  oE:lastname  := oCustomer:lastname
  oE:email     := oCustomer:email
  oE:phone     := oCustomer:phone
  oE:street    := oCustomer:street
  oE:city      := oCustomer:city
  oE:state     := oCustomer:state
  oE:zipcode   := oCustomer:zipcode
  oE:country   := oCustomer:country
  oE:active    := oCustomer:active
  oE:notes     := oCustomer:notes
  oWAC:toWorkarea( oE )
  DbCommit()
  oWAC:doRecordUnlock()
  oCustomer := oWAC:fromWorkarea()

  oWAC:close()
RETURN .T.


/// <summary>
/// Deletes all records matching the given cust_id.
/// Uses a DO WHILE DbSeek loop (no DbSkip) as per pattern.
/// Locks each record before deleting, then unlocks.
/// </summary>
///
/// <param name="cId">Customer ID of the record(s) to delete</param>
/// <returns>Logical: .T. if deleted successfully, .F. if not found or on open failure</returns>
///
CLASS METHOD CustomerDataMgr:delete( cId )
  LOCAL oWAC

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN .F.
  ENDIF

  OrdSetFocus("cust_id")
  IF !DbSeek( cId )
    oWAC:close()
    RETURN .F.
  ENDIF

  DO WHILE DbSeek( cId )
    oWAC:tryRecordLock()
    DbDelete()
    DbCommit()
    oWAC:doRecordUnlock()
  ENDDO

  oWAC:close()
RETURN .T.
