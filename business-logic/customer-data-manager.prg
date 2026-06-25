//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Customer Data Manager - Business logic layer for customer operations
/// </summary>
///
/// <remarks>
/// This class handles all CRUD operations for customer data.
/// Uses the WAContainer pattern for efficient, stateless workarea
/// management - modelled after the rbac-svc RbacManager / WAC* classes.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "dmlb.ch"

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
  CLASS METHOD delete( cId )
ENDCLASS

/*
  CLASS METHOD getAll()
  Returns an array of all customer records (not deleted).
  Uses the cust_id index for ordered traversal.
*/
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

/*
  CLASS METHOD getById( cId )
  Returns a single customer record matching the given cust_id.
  Uses the cust_id TAG (plain field value, no transformation).
*/
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

/*
  CLASS METHOD getByName( cName )
  Returns an array of customer records matching the given name fragment.
  Index key expression: Upper( lastname + firstname )
  cName should be passed as already-uppercased or will be uppercased here.
*/
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
  DO WHILE OrdKeyVal() = cSeekVal
    oEntry := oWAC:fromWorkarea()
    AAdd( aRet, oEntry )
    DbSkip(1)
  ENDDO

  oWAC:close()
RETURN aRet

/*
  CLASS METHOD getByEmail( cEmail )
  Returns a single customer record matching the given email address.
  Index key expression: Upper( email )
*/
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

/*
  CLASS METHOD getByCity( cCity )
  Returns an array of customer records located in the given city.
  Index key expression: Upper( city )
*/
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
  DO WHILE OrdKeyVal() = cSeekVal
    oEntry := oWAC:fromWorkarea()
    AAdd( aRet, oEntry )
    DbSkip(1)
  ENDDO

  oWAC:close()
RETURN aRet

/*
  CLASS METHOD getActive()
  Returns an array of all active customer records.
  Index key expression: active (logical field)
  Seeks .T. to find all active customers.
*/
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
  DO WHILE OrdKeyVal() == .T.
    oEntry := oWAC:fromWorkarea()
    AAdd( aRet, oEntry )
    DbSkip(1)
  ENDDO

  oWAC:close()
RETURN aRet

/*
  CLASS METHOD update( cId, oCustomer )
  Updates an existing customer record identified by cust_id.
  Locks the record, writes the new data, then unlocks.
  Does NOT touch created or modified fields (maintained by WAC).
*/
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

/*
  CLASS METHOD add( oCustomer )
  Appends a new customer record.
  Checks for duplicate cust_id before inserting.
  created and modified are maintained by WAC - not set here.
*/
CLASS METHOD CustomerDataMgr:add( oCustomer )
  LOCAL oWAC, oE

  oWAC := wacCustomer():open()
  IF IsNull(oWAC)
    RETURN .F.
  ENDIF

  // Check for duplicate cust_id
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

  oWAC:close()
RETURN .T.

/*
  CLASS METHOD delete( cId )
  Deletes all records matching the given cust_id.
  Uses a DO WHILE DbSeek loop (no DbSkip) as per pattern.
  Locks each record before deleting, then unlocks.
*/
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
    oWAC:doRecordUnlock()
  ENDDO

  oWAC:close()
RETURN .T.
