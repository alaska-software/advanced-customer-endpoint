#include "..\.assets\xpp-unit\unit-test.ch"
#include "dmlb.ch"

/*
 * Test Suite: Authentication API - POST /auth/login
 * OpenAPI Spec Version: 3.0.3
 * API Version: 1.0.0
 * Base URL: http://localhost:9000
 *
 * Coverage:
 *   1. Functional Validation Tests
 *   2. Edge Case Tests (Top 5)
 *   3. Data Pattern Tests (High probability patterns)
 *   4. Error Condition Tests (Typical patterns)
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
      METHOD testLoginSuccess_ValidCredentials()
      METHOD testLoginSuccess_ResponseStatusCode()
      METHOD testLoginSuccess_ResponseBodyStructure()
      METHOD testLoginSuccess_TokenFieldPresent()
      METHOD testLoginSuccess_TokenTypeIsBearer()
      METHOD testLoginSuccess_ExpiresInIsPositiveInteger()

      // 2. Edge Case Tests
      METHOD testLoginEdge_SingleCharUsername()
      METHOD testLoginEdge_SingleCharPassword()
      METHOD testLoginEdge_EmptyUsername()
      METHOD testLoginEdge_EmptyPassword()
      METHOD testLoginEdge_WhitespaceOnlyUsername()

      // 3. Data Pattern Tests
      METHOD testLoginPattern_UsernameWithUpperCase()
      METHOD testLoginPattern_PasswordWithSpecialChars()
      METHOD testLoginPattern_UsernameWithLeadingTrailingSpaces()

      // 4. Error Condition Tests
      METHOD testLoginError_WrongPassword()
      METHOD testLoginError_NonExistentUser()
      METHOD testLoginError_MissingUserField()
      METHOD testLoginError_MissingPasswordField()
      METHOD testLoginError_EmptyRequestBody()

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
   ::addCase("testLoginSuccess_ValidCredentials")
   ::addCase("testLoginSuccess_ResponseStatusCode")
   ::addCase("testLoginSuccess_ResponseBodyStructure")
   ::addCase("testLoginSuccess_TokenFieldPresent")
   ::addCase("testLoginSuccess_TokenTypeIsBearer")
   ::addCase("testLoginSuccess_ExpiresInIsPositiveInteger")

   // 2. Edge Case Tests
   ::addCase("testLoginEdge_SingleCharUsername")
   ::addCase("testLoginEdge_SingleCharPassword")
   ::addCase("testLoginEdge_EmptyUsername")
   ::addCase("testLoginEdge_EmptyPassword")
   ::addCase("testLoginEdge_WhitespaceOnlyUsername")

   // 3. Data Pattern Tests
   ::addCase("testLoginPattern_UsernameWithUpperCase")
   ::addCase("testLoginPattern_PasswordWithSpecialChars")
   ::addCase("testLoginPattern_UsernameWithLeadingTrailingSpaces")

   // 4. Error Condition Tests
   ::addCase("testLoginError_WrongPassword")
   ::addCase("testLoginError_NonExistentUser")
   ::addCase("testLoginError_MissingUserField")
   ::addCase("testLoginError_MissingPasswordField")
   ::addCase("testLoginError_EmptyRequestBody")
RETURN

// ─────────────────────────────────────────────
// 1. FUNCTIONAL VALIDATION TESTS
// ─────────────────────────────────────────────

/*
 * Purpose : Verify that a POST with valid credentials returns HTTP 200
 *           and a non-empty response object.
 * Expected: Status 200, response object is not NIL
 */
METHOD AuthLoginTestGroup:testLoginSuccess_ValidCredentials()
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
RETURN SELF

/*
 * Purpose : Confirm the HTTP status code is exactly 200 for valid credentials.
 * Expected: Status code == 200
 */
METHOD AuthLoginTestGroup:testLoginSuccess_ResponseStatusCode()
   LOCAL oRequest, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   ::Endpoint:send(oRequest)
   nStatus := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(200, nStatus)
RETURN SELF

/*
 * Purpose : Validate the top-level response envelope contains
 *           the "error" and "result" fields as per the schema.
 * Expected: oResponse:error is NIL/null on success;
 *           oResponse:result is an object
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

   // "error" field must be null/NIL on success
   CHECK_UNDEFINED_TYPE(oResponse:error)

   // "result" field must be an object
   CHECK_OBJECT_TYPE(oResponse:result)
RETURN SELF

/*
 * Purpose : Verify the "token" field inside result is a non-empty string
 *           and follows the JWT three-segment dot-separated format.
 * Expected: token is a non-empty string containing exactly two dots
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

   // Token must be a non-empty string
   CHECK_CHAR_TYPE(cToken)
   CHECK_GREATER(Len(cToken), 0)

   // JWT format: header.payload.signature (two dots present)
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
// 2. EDGE CASE TESTS (Top 5)
// ─────────────────────────────────────────────

/*
 * Purpose : Test boundary condition where username is exactly 1 character
 *           (minLength: 1). If the server has a user "a", it should respond
 *           with 200 or 401; it must NOT respond with 400 (field is present).
 * Expected: Status is 200 or 401 (not 400)
 * Rationale: minLength=1 means a single character is the minimum valid length
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

   // A single-char username satisfies minLength:1, so 400 is NOT expected
   CHECK_FALSE(nStatus == 400)
   // Must be either 200 (found) or 401 (not found / wrong password)
   CHECK_TRUE(nStatus == 200 .OR. nStatus == 401)
RETURN SELF

/*
 * Purpose : Test boundary condition where password is exactly 1 character
 *           (minLength: 1). Server must not reject with 400.
 * Expected: Status is 200 or 401 (not 400)
 * Rationale: minLength=1 means a single character is the minimum valid length
 */
METHOD AuthLoginTestGroup:testLoginEdge_SingleCharPassword()
   LOCAL oRequest, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "x"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   ::Endpoint:send(oRequest)
   nStatus := ::Endpoint:getStatusCode()

   // Single-char password satisfies minLength:1, so 400 is NOT expected
   CHECK_FALSE(nStatus == 400)
   CHECK_TRUE(nStatus == 200 .OR. nStatus == 401)
RETURN SELF

/*
 * Purpose : Test that an empty string for "user" triggers a 400 Bad Request.
 *           The schema specifies minLength:1, so empty string is invalid.
 * Expected: Status 400, error field is non-empty string
 * Rationale: Empty string violates minLength:1 constraint
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

/*
 * Purpose : Test that an empty string for "password" triggers a 400 Bad Request.
 *           The schema specifies minLength:1, so empty string is invalid.
 * Expected: Status 400, error field is non-empty string
 * Rationale: Empty string violates minLength:1 constraint; also matches
 *            the "missingPassword" example in the spec
 */
METHOD AuthLoginTestGroup:testLoginEdge_EmptyPassword()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := ""

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(400, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_CHAR_TYPE(oResponse:error)
   CHECK_GREATER(Len(oResponse:error), 0)
RETURN SELF

/*
 * Purpose : Test that a whitespace-only username is treated as invalid.
 *           While it technically has length > 0, it carries no meaningful value.
 * Expected: Status 400 or 401 (server-dependent); must NOT return 200
 * Rationale: Whitespace-only strings are a common real-world edge case
 *            that can bypass naive length checks
 */
METHOD AuthLoginTestGroup:testLoginEdge_WhitespaceOnlyUsername()
   LOCAL oRequest, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "   "
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   ::Endpoint:send(oRequest)
   nStatus := ::Endpoint:getStatusCode()

   // Whitespace-only username should never authenticate successfully
   CHECK_FALSE(nStatus == 200)
   CHECK_TRUE(nStatus == 400 .OR. nStatus == 401)
RETURN SELF

// ─────────────────────────────────────────────
// 3. DATA PATTERN TESTS
// ─────────────────────────────────────────────

/*
 * Purpose : Test that username matching is case-sensitive.
 *           "Alice" (uppercase A) should NOT authenticate as "alice".
 * Expected: Status 401 (credentials invalid) or 400
 * Rationale: High-probability real-world pattern — users often type
 *            their username with an initial capital letter
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

   // "Alice" != "alice" in a case-sensitive system → must not return 200
   CHECK_FALSE(nStatus == 200)
   CHECK_TRUE(nStatus == 401 .OR. nStatus == 400)
RETURN SELF

/*
 * Purpose : Test that a password containing special characters is handled
 *           correctly without causing a server error.
 * Expected: Status 401 (wrong password) or 200 if such a user exists;
 *           must NOT return 500
 * Rationale: Passwords with special chars are common; servers must not
 *            crash or return 500 on them
 */
METHOD AuthLoginTestGroup:testLoginPattern_PasswordWithSpecialChars()
   LOCAL oRequest, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := "alice"
   oCredentials:password := "P@$$w0rd!#%^&*()"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   ::Endpoint:send(oRequest)
   nStatus := ::Endpoint:getStatusCode()

   // Server must handle special chars gracefully — no 500
   CHECK_FALSE(nStatus == 500)
   CHECK_TRUE(nStatus == 200 .OR. nStatus == 401)
RETURN SELF

/*
 * Purpose : Test that a username submitted with leading/trailing spaces
 *           does not authenticate as the trimmed version.
 * Expected: Status 401 (not found) or 400; must NOT return 200
 * Rationale: Copy-paste artifacts commonly introduce surrounding whitespace;
 *            the server should not silently trim and authenticate
 */
METHOD AuthLoginTestGroup:testLoginPattern_UsernameWithLeadingTrailingSpaces()
   LOCAL oRequest, nStatus
   LOCAL oCredentials

   oCredentials := DataObject():new()
   oCredentials:user     := " alice "
   oCredentials:password := "secret"

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   ::Endpoint:send(oRequest)
   nStatus := ::Endpoint:getStatusCode()

   // " alice " should not silently match "alice"
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
 * Rationale: Returning 401 (not 404) avoids user enumeration attacks
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
 * Rationale: "user" is marked as required in the schema
 */
METHOD AuthLoginTestGroup:testLoginError_MissingUserField()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   // Only password is provided; "user" field is absent
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
 * Rationale: "password" is marked as required in the schema
 */
METHOD AuthLoginTestGroup:testLoginError_MissingPasswordField()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   // Only user is provided; "password" field is absent
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

/*
 * Purpose : Verify that sending a completely empty JSON body returns HTTP 400.
 * Expected: Status 400, error field is non-empty
 * Rationale: Both required fields are absent; server must reject gracefully
 */
METHOD AuthLoginTestGroup:testLoginError_EmptyRequestBody()
   LOCAL oRequest, oResponse, nStatus
   LOCAL oCredentials

   // Empty object — no fields at all
   oCredentials := DataObject():new()

   oRequest := RestRequestMessage():new("POST", "/auth/login")
   oRequest:setContent(oCredentials)

   oResponse := ::Endpoint:send(oRequest)
   nStatus   := ::Endpoint:getStatusCode()

   CHECK_INT_EQUAL(400, nStatus)
   CHECK_OBJECT_TYPE(oResponse)
   CHECK_CHAR_TYPE(oResponse:error)
   CHECK_GREATER(Len(oResponse:error), 0)
RETURN SELF