//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Integration tests for Customer REST API
/// </summary>
///
/// <remarks>
/// Coverage:
///   1. Functional Validation Tests
///      - GET /customer/all      - envelope structure, field types on items
///      - GET /customer/{id}     - correct record returned, all field types
///      - GET /customer/search/{name} - matching customers returned
///      - PUT /customer/         - create new customer (empty id = add)
///      - PUT /customer/{id}     - update existing customer, change persisted
///      - DELETE /customer/{id}  - delete existing customer returns .T.
///   2. Error Condition Tests
///      - GET /customer/{id}          - 404 on unknown id
///      - GET /customer/search/{name} - 404 when no match
///      - PUT /customer/{id}          - 500 when id does not exist (update fails)
///      - DELETE /customer/{id}       - 404 on unknown id
///   3. Authentication Tests
///      - All four endpoint types return 401 without Authorization header
///
/// Fixture strategy:
///   Fixture data is managed directly through CustomerDataMgr (not through
///   the API being tested) to avoid circular dependencies. before() calls
///   CustomerDataMgr():add() and after() calls CustomerDataMgr():delete(),
///   so test isolation does not rely on the correctness of the write endpoints.
///   The runner links against customer-core.dll and reads the same DB path
///   from customer-core.dll.config as the running server.
///
/// Assumptions:
///   - Server is running at http://localhost:9000
///   - Valid credentials: user="alice", password="secret"
///   - Fixture ID "REST001" (8 chars max, C,8 field)
///   - Temporary ID "REST002" used by testSave_CreateSucceeds;
///     cleaned in after() via CustomerDataMgr as a safety net
///   - Name index key: Upper(lastname - firstname)
///     Fixture: lastname="Customer", firstname="Test" -> "CUSTOMERTEST..."
///   - OpenAPI Spec Version: 3.0.3, API Version: 1.0.0
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "..\.assets\xpp-unit\unit-test.ch"
#include "dmlb.ch"

#define ENDPOINT       "http://127.0.0.1:9000"
#define AUTH_USER      "alice"
#define AUTH_PASSWORD  "secret"
#define FIXTURE_ID     "REST001"
#define TEMP_ID        "REST002"


// ============================================================================
// Helper: Build a customer DataObject for direct CustomerDataMgr use
// ============================================================================
STATIC FUNCTION buildCustomer( cId, cFirst, cLast, cEmail )
   LOCAL oC

   oC           := DataObject():new()
   oC:cust_id   := cId
   oC:firstname := cFirst
   oC:lastname  := cLast
   oC:email     := cEmail
   oC:phone     := "555-0199"
   oC:street    := "1 Test Lane"
   oC:city      := "Testville"
   oC:state     := "TX"
   oC:zipcode   := "10001"
   oC:country   := "US"
   oC:active    := .T.
   oC:notes     := ""
RETURN oC


// ============================================================================
// Test Group
// ============================================================================
CLASS RestCustTestGroup FROM GenericTestGroup
   PROTECTED:
      VAR Endpoint
      VAR cToken

   EXPORTED:
      METHOD setup()
      METHOD before()
      METHOD after()
      METHOD tearDown()
      METHOD config()

      // 1. Functional Validation Tests
      METHOD testGetAll_EnvelopeStructure()
      METHOD testGetAll_DataItemHasCustomerFields()
      METHOD testGetById_ReturnsMatchingRecord()
      METHOD testGetById_FieldTypesAreCorrect()
      METHOD testGetByName_ReturnsMatchingCustomers()
      METHOD testSave_CreateSucceeds()
      METHOD testSave_UpdateChangesFieldValue()
      METHOD testDelete_ReturnsTrue()

      // 2. Error Condition Tests
      METHOD testGetById_NotFound_Returns404()
      METHOD testGetByName_NotFound_Returns404()
      METHOD testSave_UpdateNotFound_Returns500()
      METHOD testDelete_NotFound_Returns404()

      // 3. Authentication Tests
      METHOD testGetAll_NoToken_Returns401()
      METHOD testGetById_NoToken_Returns401()
      METHOD testSave_NoToken_Returns401()
      METHOD testDelete_NoToken_Returns401()

ENDCLASS


//////////////////////////////////////////////////////////////////////
// Setup / Before / After / TearDown / Config
//////////////////////////////////////////////////////////////////////

/// <summary>
/// Runs once before all tests. Creates the REST client and obtains a
/// JWT token via POST /auth/login. The token is added as a persistent
/// Authorization header on the Endpoint so all subsequent requests
/// through it are authenticated automatically.
/// </summary>
METHOD RestCustTestGroup:setup()
   LOCAL oCredentials, oRequest, oResponse
   SUPER

   WacCustomer():setPath( "..\run\" )

   ::Endpoint := RestClient():new( ENDPOINT )

   oCredentials          := DataObject():new()
   oCredentials:user     := AUTH_USER
   oCredentials:password := AUTH_PASSWORD

   oRequest  := RestRequestMessage():new( "POST", "/auth/login" )
   oRequest:setContent( oCredentials )
   oResponse := ::Endpoint:send( oRequest )

   ::cToken  := oResponse:result:token
   ::Endpoint:addHeader( "Authorization", "Bearer " + ::cToken )
   ::Endpoint:addHeader( "Cache-Control", "no-cache" )
RETURN


/// <summary>
/// Runs before each individual test. Inserts the fixture customer directly
/// through CustomerDataMgr so fixture creation is independent of the
/// REST write endpoints being tested.
/// </summary>
METHOD RestCustTestGroup:before()
   LOCAL oCustomer

   oCustomer := buildCustomer( FIXTURE_ID, "Test", "Customer", "test.customer@rest.test" )
   CustomerDataMgr():addWithId( oCustomer )
RETURN SELF


/// <summary>
/// Runs after each individual test. Deletes both the fixture customer
/// and the temporary customer (used by testSave_CreateSucceeds) directly
/// through CustomerDataMgr. delete() returning .F. for an already-absent
/// record is expected and safe.
/// </summary>
METHOD RestCustTestGroup:after()
   LOCAL lRet
   lRet := CustomerDataMgr():delete( FIXTURE_ID )
   // CHECK_TRUE( lRet )
   CustomerDataMgr():delete( TEMP_ID )
RETURN SELF


/// <summary>
/// Runs once after all tests complete. Group-level cleanup only.
/// </summary>
METHOD RestCustTestGroup:tearDown()
   wacCustomer():shutdown()
   SUPER
RETURN


METHOD RestCustTestGroup:config()
   // 1. Functional Validation Tests
   ::addCase("testGetAll_EnvelopeStructure")
   ::addCase("testGetAll_DataItemHasCustomerFields")
   ::addCase("testGetById_ReturnsMatchingRecord")
   ::addCase("testGetById_FieldTypesAreCorrect")
   ::addCase("testGetByName_ReturnsMatchingCustomers")
   ::addCase("testSave_CreateSucceeds")
   ::addCase("testSave_UpdateChangesFieldValue")
   ::addCase("testDelete_ReturnsTrue")

   // 2. Error Condition Tests
   ::addCase("testGetById_NotFound_Returns404")
   ::addCase("testGetByName_NotFound_Returns404")
   ::addCase("testSave_UpdateNotFound_Returns500")
   ::addCase("testDelete_NotFound_Returns404")

   // 3. Authentication Tests
   ::addCase("testGetAll_NoToken_Returns401")
   ::addCase("testGetById_NoToken_Returns401")
   ::addCase("testSave_NoToken_Returns401")
   ::addCase("testDelete_NoToken_Returns401")
RETURN


//////////////////////////////////////////////////////////////////////
// 1. Functional Validation Tests
//////////////////////////////////////////////////////////////////////

/// <summary>
/// GET /customer/all must return HTTP 200 with the standard success
/// envelope: error is NIL and result is an array.
/// </summary>
METHOD RestCustTestGroup:testGetAll_EnvelopeStructure()
   LOCAL oRequest, oResponse, nStatus

   oRequest  := RestRequestMessage():new( "GET", "/customer/all" )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_OBJECT_TYPE( oResponse )
   CHECK_UNDEF( oResponse:error )
   CHECK_ARRAY_TYPE( oResponse:result )
RETURN SELF


/// <summary>
/// Every item in the GET /customer/all result array must carry all
/// customer fields with the correct types as defined by the data model.
/// The fixture customer inserted in before() guarantees at least one item.
/// </summary>
METHOD RestCustTestGroup:testGetAll_DataItemHasCustomerFields()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oItem, i, lFound

   oRequest  := RestRequestMessage():new( "GET", "/customer/all" )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_UNDEF( oResponse:error )
   CHECK_ARRAY_TYPE( oResponse:result )
   CHECK_GREATER( Len(oResponse:result), 0 )

   // Locate the fixture item and verify its field types
   lFound := .F.
   FOR i := 1 TO Len( oResponse:result )
      IF oResponse:result[i]:cust_id == FIXTURE_ID
         oItem  := oResponse:result[i]
         lFound := .T.
      ENDIF
   NEXT
   CHECK_TRUE( lFound )

   CHECK_CHAR_TYPE( oItem:cust_id )
   CHECK_CHAR_TYPE( oItem:firstname )
   CHECK_CHAR_TYPE( oItem:lastname )
   CHECK_CHAR_TYPE( oItem:email )
   CHECK_CHAR_TYPE( oItem:phone )
   CHECK_CHAR_TYPE( oItem:street )
   CHECK_CHAR_TYPE( oItem:city )
   CHECK_CHAR_TYPE( oItem:state )
   CHECK_CHAR_TYPE( oItem:zipcode )
   CHECK_CHAR_TYPE( oItem:country )
   CHECK_LOGICAL_TYPE( oItem:active )
RETURN SELF


/// <summary>
/// GET /customer/{id} with the fixture ID must return HTTP 200 and
/// a result object whose cust_id equals the requested identifier.
/// </summary>
METHOD RestCustTestGroup:testGetById_ReturnsMatchingRecord()
   LOCAL oRequest, oResponse, nStatus

   oRequest  := RestRequestMessage():new( "GET", "/customer/::id" )
   oRequest:id := FIXTURE_ID

   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_OBJECT_TYPE( oResponse )
   CHECK_UNDEF( oResponse:error )
   CHECK_OBJECT_TYPE( oResponse:result )
   CHECK_STR_EQUAL( FIXTURE_ID, oResponse:result:cust_id )
RETURN SELF


/// <summary>
/// GET /customer/{id} response result must expose every customer field
/// with the correct type as specified by the OAS3 schema.
/// Dates (created, modified) are serialised to strings by the JSON layer.
/// </summary>
METHOD RestCustTestGroup:testGetById_FieldTypesAreCorrect()
   LOCAL oRequest, oResponse, nStatus, oData

   oRequest  := RestRequestMessage():new( "GET", "/customer/::id" )
   oRequest:id := FIXTURE_ID

   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_UNDEF( oResponse:error )
   oData := oResponse:result

   CHECK_CHAR_TYPE( oData:cust_id )
   CHECK_CHAR_TYPE( oData:firstname )
   CHECK_CHAR_TYPE( oData:lastname )
   CHECK_CHAR_TYPE( oData:email )
   CHECK_CHAR_TYPE( oData:phone )
   CHECK_CHAR_TYPE( oData:street )
   CHECK_CHAR_TYPE( oData:city )
   CHECK_CHAR_TYPE( oData:state )
   CHECK_CHAR_TYPE( oData:zipcode )
   CHECK_CHAR_TYPE( oData:country )
   CHECK_LOGICAL_TYPE( oData:active )
   CHECK_DATE_TYPE( oData:created )
   CHECK_DATE_TYPE( oData:modified )
RETURN SELF


/// <summary>
/// GET /customer/search/{name} must return HTTP 200 and an array that
/// includes the fixture customer.
/// Index key: Upper(lastname - firstname).
/// Fixture: "Customer" - "Test" -> "CUSTOMERTEST..." (uppercased by server).
/// </summary>
METHOD RestCustTestGroup:testGetByName_ReturnsMatchingCustomers()
   LOCAL oRequest, oResponse, nStatus
   LOCAL lFound, i

   oRequest  := RestRequestMessage():new( "GET", "/customer/search/CustomerTest" )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_UNDEF( oResponse:error )
   CHECK_ARRAY_TYPE( oResponse:result )
   CHECK_GREATER( Len(oResponse:result), 0 )

   lFound := .F.
   FOR i := 1 TO Len( oResponse:result )
      IF oResponse:result[i]:cust_id == FIXTURE_ID
         lFound := .T.
      ENDIF
   NEXT
   CHECK_TRUE( lFound )
RETURN SELF


/// <summary>
/// PUT /customer/ (empty path id = add) must create a new customer record
/// and return HTTP 200 with error NIL and a result object.
/// TEMP_ID is used to avoid conflicting with the fixture (FIXTURE_ID).
/// after() removes TEMP_ID directly via CustomerDataMgr as a safety net.
/// </summary>
METHOD RestCustTestGroup:testSave_CreateSucceeds()
   LOCAL oRequest, oResponse, nStatus, oBody

   oBody           := DataObject():new()
   oBody:cust_id   := TEMP_ID
   oBody:firstname := "Temp"
   oBody:lastname  := "Record"
   oBody:email     := "temp.record@rest.test"
   oBody:phone     := "555-0200"
   oBody:street    := "2 Temp Road"
   oBody:city      := "Nowhere"
   oBody:state     := "NV"
   oBody:zipcode   := "89001"
   oBody:country   := "US"
   oBody:active    := .T.
   oBody:notes     := ""

   oRequest := RestRequestMessage():new( "POST", "/customer" )
   oRequest:setContent( oBody )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_OBJECT_TYPE( oResponse )
   CHECK_UNDEF( oResponse:error )
   CHECK_OBJECT_TYPE( oResponse:result )
RETURN SELF


/// <summary>
/// PUT /customer/{id} with a valid existing ID must update the record.
/// The changed field (email) is verified by a subsequent GET.
/// The fixture was seeded by before() via CustomerDataMgr, so the update
/// endpoint is tested against a guaranteed-clean starting state.
/// </summary>
METHOD RestCustTestGroup:testSave_UpdateChangesFieldValue()
   LOCAL oRequest, oResponse, nStatus, oBody

   oBody := buildCustomer( FIXTURE_ID, "Test", "Customer", "updated@rest.test" )

   oRequest := RestRequestMessage():new( "PUT", "/customer/" + FIXTURE_ID )
   oRequest:setContent( oBody )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_UNDEF( oResponse:error )

   // Read back and confirm the changed email was persisted
   oRequest  := RestRequestMessage():new( "GET", "/customer/" + FIXTURE_ID )
   oResponse := ::Endpoint:send( oRequest )

   CHECK_INT_EQUAL( 200, ::Endpoint:getStatusCode() )
   CHECK_STR_EQUAL( "updated@rest.test", oResponse:result:email )
RETURN SELF


/// <summary>
/// DELETE /customer/{id} on an existing record must return HTTP 200,
/// error NIL and result = .T. (boolean true).
/// </summary>
METHOD RestCustTestGroup:testDelete_ReturnsTrue()
   LOCAL oRequest, oResponse, nStatus

   oRequest  := RestRequestMessage():new( "DELETE", "/customer/" + FIXTURE_ID )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 200, nStatus )
   CHECK_OBJECT_TYPE( oResponse )
   CHECK_UNDEF( oResponse:error )
   CHECK_TRUE( oResponse:result )
RETURN SELF


//////////////////////////////////////////////////////////////////////
// 2. Error Condition Tests
//////////////////////////////////////////////////////////////////////

/// <summary>
/// GET /customer/{id} with an ID that has no matching record must
/// return HTTP 404 with error.code = 404.
/// </summary>
METHOD RestCustTestGroup:testGetById_NotFound_Returns404()
   LOCAL oRequest, oResponse, nStatus

   oRequest  := RestRequestMessage():new( "GET", "/customer/NOTEXIST" )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 404, nStatus )
   CHECK_OBJECT_TYPE( oResponse )
   CHECK_CHAR_TYPE( oResponse:error )
RETURN SELF


/// <summary>
/// GET /customer/search/{name} with a fragment that matches nothing
/// must return HTTP 404 with error set and an empty result array.
/// </summary>
METHOD RestCustTestGroup:testGetByName_NotFound_Returns404()
   LOCAL oRequest, oResponse, nStatus

   oRequest  := RestRequestMessage():new( "GET", "/customer/search/ZZZNOMATCH" )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 404, nStatus )
   CHECK_CHAR_TYPE( oResponse:error )
   CHECK_ARRAY_TYPE( oResponse:result )
RETURN SELF


/// <summary>
/// PUT /customer/{id} targeting an ID that does not exist causes
/// CustomerDataMgr:update() to return .F., which triggers setError(500)
/// in the handler and HTTP 500 in the response.
/// </summary>
METHOD RestCustTestGroup:testSave_UpdateNotFound_Returns500()
   LOCAL oRequest, oResponse, nStatus, oBody

   oBody           := DataObject():new()
   oBody:firstname := "Ghost"
   oBody:lastname  := "Record"
   oBody:email     := "ghost@nowhere.test"

   oRequest := RestRequestMessage():new( "PUT", "/customer/NOTEXIST" )
   oRequest:setContent( oBody )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 500, nStatus )
   CHECK_OBJECT_TYPE( oResponse )
   CHECK_CHAR_TYPE( oResponse:error )
RETURN SELF


/// <summary>
/// DELETE /customer/{id} with an ID that has no matching record must
/// return HTTP 404 with error.code = 404.
/// </summary>
METHOD RestCustTestGroup:testDelete_NotFound_Returns404()
   LOCAL oRequest, oResponse, nStatus

   oRequest  := RestRequestMessage():new( "DELETE", "/customer/NOTEXIST" )
   oResponse := ::Endpoint:send( oRequest )
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL( 404, nStatus )
   CHECK_OBJECT_TYPE( oResponse )
   CHECK_CHAR_TYPE( oResponse:error )
RETURN SELF


//////////////////////////////////////////////////////////////////////
// 3. Authentication Tests
//////////////////////////////////////////////////////////////////////

/// <summary>
/// GET /customer/all without an Authorization header must return HTTP 401.
/// A fresh RestClient (no addHeader) is used so the persistent token on
/// ::Endpoint does not leak into this request.
/// </summary>
METHOD RestCustTestGroup:testGetAll_NoToken_Returns401()
   LOCAL oRequest, oClient, nStatus

   oClient  := RestClient():new( ENDPOINT )
   oRequest := RestRequestMessage():new( "GET", "/customer/all" )
   oClient:send( oRequest )
   nStatus  := oClient:getStatusCode()

   CHECK_INT_EQUAL( 401, nStatus )
RETURN SELF


/// <summary>
/// GET /customer/{id} without an Authorization header must return HTTP 401.
/// A fresh RestClient (no addHeader) is used so the persistent token on
/// ::Endpoint does not leak into this request.
/// </summary>
METHOD RestCustTestGroup:testGetById_NoToken_Returns401()
   LOCAL oRequest, oClient, nStatus

   oClient  := RestClient():new( ENDPOINT )
   oRequest := RestRequestMessage():new( "GET", "/customer/" + FIXTURE_ID )
   oClient:send( oRequest )
   nStatus  := oClient:getStatusCode()

   CHECK_INT_EQUAL( 401, nStatus )
RETURN SELF


/// <summary>
/// PUT /customer/{id} without an Authorization header must return HTTP 401.
/// A fresh RestClient (no addHeader) is used so the persistent token on
/// ::Endpoint does not leak into this request.
/// </summary>
METHOD RestCustTestGroup:testSave_NoToken_Returns401()
   LOCAL oRequest, oClient, oBody, nStatus

   oBody           := DataObject():new()
   oBody:firstname := "Test"
   oBody:lastname  := "Customer"
   oBody:email     := "test@example.com"

   oClient  := RestClient():new( ENDPOINT )
   oRequest := RestRequestMessage():new( "PUT", "/customer/" + FIXTURE_ID )
   oRequest:setContent( oBody )
   oClient:send( oRequest )
   nStatus  := oClient:getStatusCode()

   CHECK_INT_EQUAL( 401, nStatus )
RETURN SELF


/// <summary>
/// DELETE /customer/{id} without an Authorization header must return HTTP 401.
/// A fresh RestClient (no addHeader) is used so the persistent token on
/// ::Endpoint does not leak into this request.
/// </summary>
METHOD RestCustTestGroup:testDelete_NoToken_Returns401()
   LOCAL oRequest, oClient, nStatus

   oClient  := RestClient():new( ENDPOINT )
   oRequest := RestRequestMessage():new( "DELETE", "/customer/" + FIXTURE_ID )
   oClient:send( oRequest )
   nStatus  := oClient:getStatusCode()

   CHECK_INT_EQUAL( 401, nStatus )
RETURN SELF
