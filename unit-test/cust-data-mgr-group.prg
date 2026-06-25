//////////////////////////////////////////////////////////////////////
/// <summary>
/// Tests for CustomerDataMgr CRUD operations (getAll, getById,
/// getByName, save, delete).
/// </summary>
///
/// <remarks>
/// Each test runs against a fresh, isolated DBFCDX table located in
/// ".\test_data\". The table is created once per group in setup() and
/// re-seeded with three known fixture customers in before() so every
/// test starts with the same, predictable state.
/// <para/>
/// The fixture is populated through direct workarea operations rather
/// than CustomerDataMgr():save() to keep the tests of save() self-
/// contained and free of circular dependencies.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
//////////////////////////////////////////////////////////////////////
#include "common.ch"
#include "..\.assets\xpp-unit\unit-test.ch"

// ============================================================================
// Helper: Build a minimal customer object for test use
// ============================================================================
STATIC FUNCTION buildCustomer( cId, cFirst, cLast, cEmail, cCity, cState, lActive )
  LOCAL oC
  oC            := DataObject():new()
  oC:cust_id    := cId
  oC:firstname  := cFirst
  oC:lastname   := cLast
  oC:email      := cEmail
  oC:phone      := "555-0100"
  oC:street     := "123 Main St"
  oC:city       := cCity
  oC:state      := cState
  oC:zipcode    := "10001"
  oC:country    := "US"
  oC:active     := lActive
  oC:notes      := ""
RETURN oC


// ============================================================================
// Test Group: CustomerDataMgr
// ============================================================================
CLASS CustomerDataMgrTests FROM GenericTestGroup
  PROTECTED:
  VAR cId1
  VAR cId2
  VAR cId3
  VAR cIdUnique

  EXPORTED:
  METHOD setup()
  METHOD tearDown()
  METHOD config()

  // --- Core Functionality ---
  METHOD testGetAllReturnsArray()
  METHOD testGetAllOrderedByCustId()
  METHOD testGetByIdReturnsCorrectRecord()
  METHOD testGetByNameReturnsMatchingRecords()
  METHOD testGetByEmailReturnsCorrectRecord()
  METHOD testGetByCityReturnsMultipleRecords()
  METHOD testGetActiveReturnsOnlyActiveRecords()

  // --- Edge Cases ---
  METHOD testGetByIdNotFound()
  METHOD testGetByNameNotFound()
  METHOD testGetByEmailNotFound()
  METHOD testGetByCityNotFound()
  METHOD testGetActiveWhenNoneActive()
  METHOD testGetByNameCaseInsensitive()
  METHOD testGetByCityCaseInsensitive()

  // --- Write Operations: add ---
  METHOD testAddNewCustomerSucceeds()
  METHOD testAddDuplicateIdFails()
  METHOD testAddAppearsInGetAll()

  // --- Write Operations: update ---
  METHOD testUpdateExistingCustomerSucceeds()
  METHOD testUpdateChangesFieldValues()
  METHOD testUpdateNonExistentIdFails()
  METHOD testUpdateDoesNotChangeId()

  // --- Write Operations: delete ---
  METHOD testDeleteExistingCustomerSucceeds()
  METHOD testDeleteRemovedFromGetAll()
  METHOD testDeleteNonExistentIdFails()

  // --- Real-World Lifecycle ---
  METHOD testFullCrudLifecycle()
  METHOD testMultiCustomerCityQuery()
ENDCLASS


METHOD CustomerDataMgrTests:setup()
  LOCAL oC1, oC2, oC3
  SUPER

  CreateCustomerTable( "./" )
  USE ("./customer")
  CreateCustomerIndexes()
  USE

  // Unique IDs per test run to avoid cross-test pollution
  ::cId1      := "TST-001"
  ::cId2      := "TST-002"
  ::cId3      := "TST-003"
  ::cIdUnique := "TST-UNQ"

  // Seed baseline records used across multiple tests
  oC1 := buildCustomer( ::cId1, "Alice",   "Smith",   "alice@example.com",  "Springfield", "IL", .T. )
  oC2 := buildCustomer( ::cId2, "Bob",     "Smith",   "bob@example.com",    "Springfield", "IL", .T. )
  oC3 := buildCustomer( ::cId3, "Charlie", "Johnson", "charlie@example.com","Shelbyville",  "IL", .F. )

  CustomerDataMgr():add( oC1 )
  CustomerDataMgr():add( oC2 )
  CustomerDataMgr():add( oC3 )
RETURN


METHOD CustomerDataMgrTests:tearDown()
  // Clean up all seeded test records regardless of test outcome
  CustomerDataMgr():delete( ::cId1 )
  CustomerDataMgr():delete( ::cId2 )
  CustomerDataMgr():delete( ::cId3 )
  CustomerDataMgr():delete( ::cIdUnique )
  SUPER
RETURN


METHOD CustomerDataMgrTests:config()
  // --- Core Functionality ---
  ::addCase("testGetAllReturnsArray")
  ::addCase("testGetAllOrderedByCustId")
  ::addCase("testGetByIdReturnsCorrectRecord")
  ::addCase("testGetByNameReturnsMatchingRecords")
  ::addCase("testGetByEmailReturnsCorrectRecord")
  ::addCase("testGetByCityReturnsMultipleRecords")
  ::addCase("testGetActiveReturnsOnlyActiveRecords")

  // --- Edge Cases ---
  ::addCase("testGetByIdNotFound")
  ::addCase("testGetByNameNotFound")
  ::addCase("testGetByEmailNotFound")
  ::addCase("testGetByCityNotFound")
  ::addCase("testGetActiveWhenNoneActive")
  ::addCase("testGetByNameCaseInsensitive")
  ::addCase("testGetByCityCaseInsensitive")

  // --- Write: add ---
  ::addCase("testAddNewCustomerSucceeds")
  ::addCase("testAddDuplicateIdFails")
  ::addCase("testAddAppearsInGetAll")

  // --- Write: update ---
  ::addCase("testUpdateExistingCustomerSucceeds")
  ::addCase("testUpdateChangesFieldValues")
  ::addCase("testUpdateNonExistentIdFails")
  ::addCase("testUpdateDoesNotChangeId")

  // --- Write: delete ---
  ::addCase("testDeleteExistingCustomerSucceeds")
  ::addCase("testDeleteRemovedFromGetAll")
  ::addCase("testDeleteNonExistentIdFails")

  // --- Real-World Lifecycle ---
  ::addCase("testFullCrudLifecycle")
  ::addCase("testMultiCustomerCityQuery")
RETURN


// ============================================================================
// Core Functionality Tests
// ============================================================================

METHOD CustomerDataMgrTests:testGetAllReturnsArray()
  // getAll() must return an array (never NIL when DB is accessible)
  LOCAL aAll
  aAll := CustomerDataMgr():getAll()
  CHECK_ARRAY_TYPE( aAll )
  // At minimum our 3 seeded records must be present
  CHECK_GREATER_OR_EQUAL( Len(aAll), 3 )
RETURN SELF


METHOD CustomerDataMgrTests:testGetAllOrderedByCustId()
  // getAll() uses cust_id index - result must be in ascending cust_id order
  LOCAL aAll, i, cPrev
  aAll := CustomerDataMgr():getAll()
  CHECK_ARRAY_TYPE( aAll )
  CHECK_GREATER( Len(aAll), 1 )

  cPrev := aAll[1]:cust_id
  FOR i := 2 TO Len(aAll)
    CHECK_TRUE( aAll[i]:cust_id >= cPrev )
    cPrev := aAll[i]:cust_id
  NEXT
RETURN SELF


METHOD CustomerDataMgrTests:testGetByIdReturnsCorrectRecord()
  // getById() must return the exact record for the given ID
  LOCAL oC
  oC := CustomerDataMgr():getById( ::cId1 )
  CHECK_OBJECT_TYPE( oC )
  CHECK_STR_EQUAL( ::cId1,           oC:cust_id  )
  CHECK_STR_EQUAL( "Alice",          oC:firstname )
  CHECK_STR_EQUAL( "Smith",          oC:lastname  )
  CHECK_STR_EQUAL( "alice@example.com", oC:email  )
RETURN SELF


METHOD CustomerDataMgrTests:testGetByNameReturnsMatchingRecords()
  // getByName() with "SmithAlice" should return Alice Smith
  // Index key: Upper(lastname + firstname)
  LOCAL aResult
  aResult := CustomerDataMgr():getByName( "SmithAlice" )
  CHECK_ARRAY_TYPE( aResult )
  CHECK_INT_EQUAL( 1, Len(aResult) )
  CHECK_STR_EQUAL( ::cId1, aResult[1]:cust_id )
RETURN SELF


METHOD CustomerDataMgrTests:testGetByEmailReturnsCorrectRecord()
  // getByEmail() must locate the record by email (case-insensitive index)
  LOCAL oC
  oC := CustomerDataMgr():getByEmail( "bob@example.com" )
  CHECK_OBJECT_TYPE( oC )
  CHECK_STR_EQUAL( ::cId2,  oC:cust_id  )
  CHECK_STR_EQUAL( "Bob",   oC:firstname )
RETURN SELF


METHOD CustomerDataMgrTests:testGetByCityReturnsMultipleRecords()
  // Both TST-001 and TST-002 are in Springfield - must return both
  LOCAL aResult
  LOCAL lFound1, lFound2, i

  aResult := CustomerDataMgr():getByCity( "Springfield" )
  CHECK_ARRAY_TYPE( aResult )
  CHECK_GREATER_OR_EQUAL( Len(aResult), 2 )

  // Verify both seeded IDs appear in the result
  lFound1 := .F.
  lFound2 := .F.
  FOR i := 1 TO Len(aResult)
    IF aResult[i]:cust_id == ::cId1
      lFound1 := .T.
    ENDIF
    IF aResult[i]:cust_id == ::cId2
      lFound2 := .T.
    ENDIF
  NEXT
  CHECK_TRUE( lFound1 )
  CHECK_TRUE( lFound2 )
RETURN SELF


METHOD CustomerDataMgrTests:testGetActiveReturnsOnlyActiveRecords()
  // getActive() must return only records where active == .T.
  // TST-001 and TST-002 are active; TST-003 is not
  LOCAL aResult, i, lFoundInactive
  aResult := CustomerDataMgr():getActive()
  CHECK_ARRAY_TYPE( aResult )
  CHECK_GREATER_OR_EQUAL( Len(aResult), 2 )

  // No inactive record should appear
  lFoundInactive := .F.
  FOR i := 1 TO Len(aResult)
    IF !aResult[i]:active
      lFoundInactive := .T.
    ENDIF
  NEXT
  CHECK_FALSE( lFoundInactive )
RETURN SELF


// ============================================================================
// Edge Cases
// ============================================================================

METHOD CustomerDataMgrTests:testGetByIdNotFound()
  // getById() with a non-existent ID must return NIL
  LOCAL oC
  oC := CustomerDataMgr():getById( "DOES-NOT-EXIST-999" )
  CHECK_UNDEFINED_TYPE( oC )
RETURN SELF


METHOD CustomerDataMgrTests:testGetByNameNotFound()
  // getByName() with no matching name must return an empty array (not NIL)
  LOCAL aResult
  aResult := CustomerDataMgr():getByName( "ZZZNOMATCH" )
  CHECK_ARRAY_TYPE( aResult )
  CHECK_INT_EQUAL( 0, Len(aResult) )
RETURN SELF


METHOD CustomerDataMgrTests:testGetByEmailNotFound()
  // getByEmail() with unknown email must return NIL
  LOCAL oC
  oC := CustomerDataMgr():getByEmail( "nobody@nowhere.invalid" )
  CHECK_UNDEFINED_TYPE( oC )
RETURN SELF


METHOD CustomerDataMgrTests:testGetByCityNotFound()
  // getByCity() with unknown city must return an empty array (not NIL)
  LOCAL aResult
  aResult := CustomerDataMgr():getByCity( "AtlantisUnknownCity" )
  CHECK_ARRAY_TYPE( aResult )
  CHECK_INT_EQUAL( 0, Len(aResult) )
RETURN SELF


METHOD CustomerDataMgrTests:testGetActiveWhenNoneActive()
  // When no active customers exist for a specific scenario,
  // getActive() must return an empty array - validated by checking
  // that TST-003 (inactive) is never included in active results
  LOCAL aResult, i
  aResult := CustomerDataMgr():getActive()
  CHECK_ARRAY_TYPE( aResult )

  FOR i := 1 TO Len(aResult)
    CHECK_FALSE( aResult[i]:cust_id == ::cId3 )
  NEXT
RETURN SELF


METHOD CustomerDataMgrTests:testGetByNameCaseInsensitive()
  // getByName() uppercases input internally - lowercase input must still match
  LOCAL aUpper, aLower
  aUpper := CustomerDataMgr():getByName( "SMITHALICE" )
  aLower := CustomerDataMgr():getByName( "smithalice" )

  CHECK_ARRAY_TYPE( aUpper )
  CHECK_ARRAY_TYPE( aLower )
  CHECK_INT_EQUAL( Len(aUpper), Len(aLower) )

  IF Len(aUpper) > 0 .AND. Len(aLower) > 0
    CHECK_STR_EQUAL( aUpper[1]:cust_id, aLower[1]:cust_id )
  ENDIF
RETURN SELF


METHOD CustomerDataMgrTests:testGetByCityCaseInsensitive()
  // getByCity() uppercases input - mixed-case city must return same result
  LOCAL aMixed, aUpper
  aMixed := CustomerDataMgr():getByCity( "springfield" )
  aUpper := CustomerDataMgr():getByCity( "SPRINGFIELD" )

  CHECK_ARRAY_TYPE( aMixed )
  CHECK_ARRAY_TYPE( aUpper )
  CHECK_INT_EQUAL( Len(aUpper), Len(aMixed) )
RETURN SELF


// ============================================================================
// Write Operations: add
// ============================================================================

METHOD CustomerDataMgrTests:testAddNewCustomerSucceeds()
  // add() with a fresh unique ID must return .T.
  LOCAL oC, lResult
  oC      := buildCustomer( ::cIdUnique, "Dana", "Lee", "dana@example.com", "Portland", "OR", .T. )
  lResult := CustomerDataMgr():add( oC )
  CHECK_TRUE( lResult )
RETURN SELF


METHOD CustomerDataMgrTests:testAddDuplicateIdFails()
  // add() with an already-existing cust_id must return .F. (duplicate guard)
  LOCAL oC, lResult
  oC      := buildCustomer( ::cId1, "Duplicate", "Person", "dup@example.com", "Nowhere", "XX", .T. )
  lResult := CustomerDataMgr():add( oC )
  CHECK_FALSE( lResult )
RETURN SELF


METHOD CustomerDataMgrTests:testAddAppearsInGetAll()
  // After a successful add(), the new record must be retrievable via getAll()
  LOCAL oC, aAll, i, lFound
  oC := buildCustomer( ::cIdUnique, "Eve", "Turner", "eve@example.com", "Austin", "TX", .T. )
  CustomerDataMgr():add( oC )

  aAll  := CustomerDataMgr():getAll()
  lFound := .F.
  FOR i := 1 TO Len(aAll)
    IF aAll[i]:cust_id == ::cIdUnique
      lFound := .T.
    ENDIF
  NEXT
  CHECK_TRUE( lFound )
RETURN SELF


// ============================================================================
// Write Operations: update
// ============================================================================

METHOD CustomerDataMgrTests:testUpdateExistingCustomerSucceeds()
  // update() on an existing record must return .T.
  LOCAL oC, lResult
  oC         := buildCustomer( ::cId1, "Alice", "Smith-Updated", "alice@example.com", "Springfield", "IL", .T. )
  lResult    := CustomerDataMgr():update( ::cId1, oC )
  CHECK_TRUE( lResult )
RETURN SELF


METHOD CustomerDataMgrTests:testUpdateChangesFieldValues()
  // After update(), getById() must reflect the new field values
  LOCAL oC, oUpdated
  oC           := buildCustomer( ::cId1, "Alice", "Smith", "alice.new@example.com", "Chicago", "IL", .T. )
  CustomerDataMgr():update( ::cId1, oC )

  oUpdated := CustomerDataMgr():getById( ::cId1 )
  CHECK_OBJECT_TYPE( oUpdated )
  CHECK_STR_EQUAL( "alice.new@example.com", oUpdated:email )
  CHECK_STR_EQUAL( "Chicago",               oUpdated:city  )
RETURN SELF


METHOD CustomerDataMgrTests:testUpdateNonExistentIdFails()
  // update() targeting a non-existent ID must return .F.
  LOCAL oC, lResult
  oC      := buildCustomer( "GHOST-999", "Ghost", "Record", "ghost@example.com", "Nowhere", "XX", .T. )
  lResult := CustomerDataMgr():update( "GHOST-999", oC )
  CHECK_FALSE( lResult )
RETURN SELF


METHOD CustomerDataMgrTests:testUpdateDoesNotChangeId()
  // update() must preserve cust_id even if caller passes a different one in oCustomer
  LOCAL oC, oAfter
  LOCAL oGhost

  // Attempt to sneak in a different cust_id via the object
  oC          := buildCustomer( ::cId1, "Alice", "Smith", "alice@example.com", "Springfield", "IL", .T. )
  oC:cust_id  := "TAMPERED-ID"   // implementation must override this with cId param
  CustomerDataMgr():update( ::cId1, oC )

  oAfter := CustomerDataMgr():getById( ::cId1 )
  CHECK_OBJECT_TYPE( oAfter )
  CHECK_STR_EQUAL( ::cId1, oAfter:cust_id )

  // Tampered ID must not exist
  oGhost := CustomerDataMgr():getById( "TAMPERED-ID" )
  CHECK_UNDEFINED_TYPE( oGhost )
RETURN SELF


// ============================================================================
// Write Operations: delete
// ============================================================================

METHOD CustomerDataMgrTests:testDeleteExistingCustomerSucceeds()
  // delete() on an existing record must return .T.
  LOCAL lResult
  lResult := CustomerDataMgr():delete( ::cId3 )
  CHECK_TRUE( lResult )
RETURN SELF


METHOD CustomerDataMgrTests:testDeleteRemovedFromGetAll()
  // After delete(), the record must no longer appear in getAll()
  LOCAL aAll, i, lFound
  CustomerDataMgr():delete( ::cId3 )

  aAll   := CustomerDataMgr():getAll()
  lFound := .F.
  FOR i := 1 TO Len(aAll)
    IF aAll[i]:cust_id == ::cId3
      lFound := .T.
    ENDIF
  NEXT
  CHECK_FALSE( lFound )
RETURN SELF


METHOD CustomerDataMgrTests:testDeleteNonExistentIdFails()
  // delete() targeting a non-existent ID must return .F.
  LOCAL lResult
  lResult := CustomerDataMgr():delete( "NO-SUCH-RECORD-XYZ" )
  CHECK_FALSE( lResult )
RETURN SELF


// ============================================================================
// Real-World Lifecycle Tests
// ============================================================================

METHOD CustomerDataMgrTests:testFullCrudLifecycle()
  // Validates the complete add -> read -> update -> delete cycle
  // for a single customer record using ::cIdUnique
  LOCAL oNew, oRead, oMod, oAfterUpdate, oAfterDelete
  LOCAL lAdd, lUpdate, lDelete
  LOCAL cCrudId := "CRUD01"
  
  // 1. Add
  oNew    := buildCustomer( cCrudId, "Frank", "Castle", "frank@example.com", "NewYork", "NY", .T. )
  lAdd    := CustomerDataMgr():add( oNew )
  CHECK_TRUE( lAdd )

  // 2. Read back
  oRead := CustomerDataMgr():getById( cCrudId )
  CHECK_OBJECT_TYPE( oRead )
  CHECK_STR_EQUAL( "Frank",  oRead:firstname )
  CHECK_STR_EQUAL( "Castle", oRead:lastname  )

  // 3. Update
  oMod           := buildCustomer( cCrudId, "Frank", "Castle", "frank.updated@example.com", "Brooklyn", "NY", .T. )
  lUpdate        := CustomerDataMgr():update( cCrudId, oMod )
  CHECK_TRUE( lUpdate )

  oAfterUpdate := CustomerDataMgr():getById( cCrudId )
  CHECK_OBJECT_TYPE( oAfterUpdate )
  CHECK_STR_EQUAL( "frank.updated@example.com", oAfterUpdate:email )
  CHECK_STR_EQUAL( "Brooklyn",                  oAfterUpdate:city  )

  // 4. Delete
  lDelete := CustomerDataMgr():delete( cCrudId )
  CHECK_TRUE( lDelete )

  oAfterDelete := CustomerDataMgr():getById( cCrudId )
  CHECK_UNDEFINED_TYPE( oAfterDelete )
RETURN SELF


METHOD CustomerDataMgrTests:testMultiCustomerCityQuery()
  // Validates that getByCity() correctly aggregates multiple customers
  // in the same city and that each returned record has the correct city value
  LOCAL aResult, i
  LOCAL lFound1, lFound2

  aResult := CustomerDataMgr():getByCity( "Springfield" )

  CHECK_ARRAY_TYPE( aResult )
  CHECK_GREATER_OR_EQUAL( Len(aResult), 2 )

  // Every returned record must actually be in Springfield
  FOR i := 1 TO Len(aResult)
    CHECK_STR_NOCASE_EQUAL( "Springfield", aResult[i]:city )
  NEXT

  // Verify both known Springfield customers are present
  lFound1 := .F.
  lFound2 := .F.
  FOR i := 1 TO Len(aResult)
    IF aResult[i]:cust_id == ::cId1
      lFound1 := .T.
    ENDIF
    IF aResult[i]:cust_id == ::cId2
      lFound2 := .T.
    ENDIF
  NEXT
  CHECK_TRUE( lFound1 )
  CHECK_TRUE( lFound2 )
RETURN SELF
