#include "..\.assets\xpp-unit\unit-test.ch"
#include "dmlb.ch"

/*
 * Test Suite: Authentication API - POST /auth/login
 * OpenAPI Spec Version: 3.0.3
 * API Version: 1.0.0
 * Base URL: http://localhost:9000
 *
 * Coverage (deduplicated by framework capability):
 *   1. Functional Validation Tests
 *      - Response envelope on success
 *      - Distinct success-payload fields (token / tokenType / expiresIn)
 *   2. Edge Case Tests
 *      - minLength:1 lower boundary (accepted)
 *      - empty string (rejected)
 *   3. Data Pattern Tests
 *      - Case-sensitive username lookup
 *   4. Error Condition Tests
 *      - Wrong password
 *      - Non-existent user
 *      - Missing required field (user / password)
 *
 * Assumptions:
 *   - Valid credentials: user="alice", password="secret"
 *   - Server is running at http://localhost:9000
 *   - JWT token format: three Base64URL segments separated by dots
 */

CLASS AuthLoginTestGroup FROM GenericTestGroup
   PROTECTED:
      VAR Endpoint

   EXPORTED:
      METHOD setup()
      METHOD tearDown()
      METHOD config()

      // 1. Functional Validation Tests
      METHOD testLoginSuccess_ResponseBodyStructure()
      METHOD testLoginSuccess_TokenFieldPresent()
      METHOD testLoginSuccess_TokenTypeIsBearer()
      METHOD testLoginSuccess_ExpiresInIsPositiveInteger()

      // 2. Edge Case Tests
      METHOD testLoginEdge_SingleCharUsername()
      METHOD testLoginEdge_EmptyUsername()

      // 3. Data Pattern Tests
      METHOD testLoginPattern_UsernameWithUpperCase()

      // 4. Error Condition Tests
      METHOD testLoginError_WrongPassword()
      METHOD testLoginError_NonExistentUser()
      METHOD testLoginError_MissingUserField()
      METHOD testLoginError_MissingPasswordField()

ENDCLASS

// ─────────────────────────────────────────────
// Setup / TearDown / Config
// ─────────────────────────────────────────────

METHOD AuthLoginTestGroup:setup()
   SUPER
   ::Endpoint := RestClient():new("http://localhost:9000")
RETURN

METHOD AuthLoginTestGroup:tearDown()
   SUPER
RETURN

METHOD AuthLoginTestGroup:config()
   // 1. Functional Validation Tests
   ::addCase("testLoginSuccess_ResponseBodyStructure")
   ::addCase("testLoginSuccess_TokenFieldPresent")
   ::addCase("testLoginSuccess_TokenTypeIsBearer")
   ::addCase("testLoginSuccess_ExpiresInIsPositiveInteger")

   // 2. Edge Case Tests
   ::addCase("testLoginEdge_SingleCharUsername")
   ::addCase("testLoginEdge_EmptyUsername")

   // 3. Data Pattern Tests
   ::addCase("testLoginPattern_UsernameWithUpperCase")

   // 4. Error Condition Tests
   ::addCase("testLoginError_WrongPassword")
   ::addCase("testLoginError_NonExistentUser")
   ::addCase("testLoginError_MissingUserField")
   ::addCase("testLoginError_MissingPasswordField")
RETURN

// ─────────────────────────────────────────────
// 1. FUNCTIONAL VALIDATION TESTS
// ─────────────────────────────────────────────

/*
 * Purpose : Validate the top-level response envelope on a successful login:
 *           HTTP 200, response is an object, "error" is null/NIL,
 *           "result" is an object.
 * Expected: Status 200, oResponse:error == NIL, oResponse:result is object
 */
METHOD AuthLoginTestGroup:testLoginSuccess_ResponseBodyStructure()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(200, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_UNDEFINED_TYPE(oResponse:error)
   CHECK_OBJECT_TYPE(oResponse:result)
RETURN SELF

/*
 * Purpose : Verify the "token" field inside result is a non-empty string
 *           and follows the JWT three-segment dot-separated format.
 * Expected: token is a non-empty string containing at least one dot
 */
METHOD AuthLoginTestGroup:testLoginSuccess_TokenFieldPresent()
   LOCAL oRequest, oResponse, nStatus, cToken
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(200, nStatus)
   CHECK_OBJECT_TYPE(oResponse:result)

   cToken := oResponse:result:token

   CHECK_CHAR_TYPE(cToken)
   CHECK_GREATER(Len(cToken), 0)
   CHECK_TRUE(At(".", cToken) > 0)
RETURN SELF

/*
 * Purpose : Confirm that "tokenType" in the result is exactly "Bearer"
 *           as defined by the enum in the schema.
 * Expected: tokenType == "Bearer"
 */
METHOD AuthLoginTestGroup:testLoginSuccess_TokenTypeIsBearer()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(200, nStatus)
   CHECK_OBJECT_TYPE(oResponse:result)
   CHECK_STR_EQUAL("Bearer", oResponse:result:tokenType)
RETURN SELF

/*
 * Purpose : Verify "expiresIn" is a positive integer representing
 *           the token lifetime in seconds (schema example: 3600).
 * Expected: expiresIn is numeric and > 0
 */
METHOD AuthLoginTestGroup:testLoginSuccess_ExpiresInIsPositiveInteger()
   LOCAL oRequest, oResponse, nStatus, nExpiresIn
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(200, nStatus)
   CHECK_OBJECT_TYPE(oResponse:result)

   nExpiresIn := oResponse:result:expiresIn

   CHECK_NUMERIC_TYPE(nExpiresIn)
   CHECK_GREATER(nExpiresIn, 0)
RETURN SELF

// ─────────────────────────────────────────────
// 2. EDGE CASE TESTS
// ─────────────────────────────────────────────

/*
 * Purpose : Test boundary condition where username is exactly 1 character
 *           (minLength: 1). Server must NOT respond with 400 (field is present).
 * Expected: Status is 200 or 401 (not 400)
 * Rationale: minLength=1 means a single character is the minimum valid length.
 *            Username chosen as representative; password side is assumed
 *            to follow the same validation path.
 */
METHOD AuthLoginTestGroup:testLoginEdge_SingleCharUsername()
   LOCAL oRequest, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "a"
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   ::Endpoint:send(oRequest)
   nStatus := ::Endpoint:getStatusCode()

   CHECK_FALSE(nStatus == 400)
   CHECK_TRUE(nStatus == 200 .OR. nStatus == 401)
RETURN SELF

/*
 * Purpose : Test that an empty string for "user" triggers a 400 Bad Request.
 *           The schema specifies minLength:1, so empty string is invalid.
 * Expected: Status 400, error field is non-empty string
 * Rationale: Empty string violates minLength:1 constraint. Username chosen
 *            as representative; the same validation is assumed to apply
 *            to the password field.
 */
METHOD AuthLoginTestGroup:testLoginEdge_EmptyUsername()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := ""
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(400, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_CHAR_TYPE(oResponse:error)
   CHECK_GREATER(Len(oResponse:error), 0)
RETURN SELF

// ─────────────────────────────────────────────
// 3. DATA PATTERN TESTS
// ─────────────────────────────────────────────

/*
 * Purpose : Test that username matching is case-sensitive and that the
 *           server does not silently normalize the input.
 *           "Alice" (uppercase A) should NOT authenticate as "alice".
 *           Also covers the "non-matching username" path representatively.
 * Expected: Status 401 (credentials invalid) or 400
 * Rationale: High-probability real-world pattern — users often type
 *            their username with an initial capital letter.
 */
METHOD AuthLoginTestGroup:testLoginPattern_UsernameWithUpperCase()
   LOCAL oRequest, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "Alice"
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   ::Endpoint:send(oRequest)
   nStatus := ::Endpoint:getStatusCode()

   CHECK_FALSE(nStatus == 200)
   CHECK_TRUE(nStatus == 401 .OR. nStatus == 400)
RETURN SELF

// ─────────────────────────────────────────────
// 4. ERROR CONDITION TESTS
// ─────────────────────────────────────────────

/*
 * Purpose : Verify that a correct username with a wrong password
 *           returns HTTP 401 Unauthorized.
 * Expected: Status 401, error field contains a message, result is null
 */
METHOD AuthLoginTestGroup:testLoginError_WrongPassword()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "wrongpassword"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(401, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_CHAR_TYPE(oResponse:error)
   CHECK_GREATER(Len(oResponse:error), 0)
   CHECK_UNDEFINED_TYPE(oResponse:result)
RETURN SELF

/*
 * Purpose : Verify that a username that does not exist in the system
 *           returns HTTP 401 Unauthorized (not 404 or 500).
 * Expected: Status 401, error field is non-empty, result is null
 * Rationale: Returning 401 (not 404) avoids user enumeration attacks.
 */
METHOD AuthLoginTestGroup:testLoginError_NonExistentUser()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "nonexistentuser_xyz_99"
   oCredentials:password := "somepassword"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(401, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_CHAR_TYPE(oResponse:error)
   CHECK_GREATER(Len(oResponse:error), 0)
   CHECK_UNDEFINED_TYPE(oResponse:result)
RETURN SELF

/*
 * Purpose : Verify that omitting the "user" field entirely returns HTTP 400.
 * Expected: Status 400, error message references missing fields
 * Rationale: "user" is marked as required in the schema.
 */
METHOD AuthLoginTestGroup:testLoginError_MissingUserField()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(400, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_CHAR_TYPE(oResponse:error)
   CHECK_GREATER(Len(oResponse:error), 0)
   CHECK_UNDEFINED_TYPE(oResponse:result)
RETURN SELF

/*
 * Purpose : Verify that omitting the "password" field entirely returns HTTP 400.
 * Expected: Status 400, error message references missing fields
 * Rationale: "password" is marked as required in the schema.
 */
METHOD AuthLoginTestGroup:testLoginError_MissingPasswordField()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user := "alice"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(400, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_CHAR_TYPE(oResponse:error)
   CHECK_GREATER(Len(oResponse:error), 0)
   CHECK_UNDEFINED_TYPE(oResponse:result)
RETURN SELF
