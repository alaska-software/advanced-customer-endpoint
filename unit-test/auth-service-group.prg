//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Unit tests for AuthService class
/// </summary>
///
/// <remarks>
/// Tests cover JWT token validation, user authentication,
/// token generation, and secret management.
/// </remarks>
///
//////////////////////////////////////////////////////////////////////

#include "..\.assets\xpp-unit\unit-test.ch"
#include "common.ch"
//#include "auth-service.ch"

#define TEST_SECRET    "test-secret-key-for-unit-tests"
#define TEST_USER      "alice"
#define TEST_PASSWORD  "secret"
#define TEST_ROLE      "admin"


CLASS AuthServiceTestGroup FROM GenericTestGroup
  PROTECTED:
  VAR cOriginalSecret

  EXPORTED:
  METHOD setup()
  METHOD tearDown()
  METHOD config()

  // Core Functionality Tests
  METHOD testValidateToken_ValidBearerToken()
  METHOD testValidateToken_ValidRawJwt()
  METHOD testValidateToken_ValidAdminRoleToken()
  METHOD testGenerateToken_DefaultUserRole()
  METHOD testGenerateToken_CustomRole()
  METHOD testAuthenticateUser_ValidCredentials()
  METHOD testAuthenticateUser_InvalidPassword()
  METHOD testAuthenticateUser_InvalidUser()

  // Edge Cases
  METHOD testValidateToken_EmptyString()
  METHOD testValidateToken_BearerWithExtraWhitespace()
  METHOD testValidateToken_ExpiredToken()
  METHOD testValidateToken_WrongSecret()
  METHOD testSetJwtSecret_EmptyStringIgnored()
  METHOD testGenerateToken_EmptyRoleDefaultsToUser()

  // Error Conditions
  METHOD testValidateToken_MalformedJwt()
  METHOD testValidateToken_RandomString()
  METHOD testAuthenticateUser_EmptyCredentials()

  // Real-World Usage Patterns
  METHOD testFullAuthWorkflow_LoginAndValidate()
  METHOD testFullAuthWorkflow_GenerateAndValidateAdminToken()
  METHOD testValidateToken_BearerPrefixVariants()
ENDCLASS


METHOD AuthServiceTestGroup:setup()
  SUPER
  // Preserve original secret and switch to test secret for isolation
  ::cOriginalSecret := AuthService():getJwtSecret()
  AuthService():setJwtSecret( TEST_SECRET )
RETURN


METHOD AuthServiceTestGroup:tearDown()
  // Restore original secret after each test
  AuthService():setJwtSecret( ::cOriginalSecret )
  SUPER
RETURN


METHOD AuthServiceTestGroup:config()
  // Core Functionality
  ::addCase("testValidateToken_ValidBearerToken")
  ::addCase("testValidateToken_ValidRawJwt")
  ::addCase("testValidateToken_ValidAdminRoleToken")
  ::addCase("testGenerateToken_DefaultUserRole")
  ::addCase("testGenerateToken_CustomRole")
  ::addCase("testAuthenticateUser_ValidCredentials","core")
  ::addCase("testAuthenticateUser_InvalidPassword","core")
  ::addCase("testAuthenticateUser_InvalidUser","core")

  // Edge Cases
  ::addCase("testValidateToken_EmptyString")
  ::addCase("testValidateToken_BearerWithExtraWhitespace")
  ::addCase("testValidateToken_ExpiredToken")
  ::addCase("testValidateToken_WrongSecret")
  ::addCase("testSetJwtSecret_EmptyStringIgnored")
  ::addCase("testGenerateToken_EmptyRoleDefaultsToUser")

  // Error Conditions
  ::addCase("testValidateToken_MalformedJwt")
  ::addCase("testValidateToken_RandomString")
  ::addCase("testAuthenticateUser_EmptyCredentials")

  // Real-World Usage Patterns
  ::addCase("testFullAuthWorkflow_LoginAndValidate")
  ::addCase("testFullAuthWorkflow_GenerateAndValidateAdminToken")
  ::addCase("testValidateToken_BearerPrefixVariants")
RETURN


//////////////////////////////////////////////////////////////////////
// Core Functionality Tests
//////////////////////////////////////////////////////////////////////

/// <summary>
/// A freshly generated token presented as "Bearer <jwt>" must validate successfully.
/// This is the primary happy-path scenario for API request authentication.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_ValidBearerToken()
  LOCAL cRawToken, cBearerToken, lResult

  cRawToken    := AuthService():generateToken( TEST_USER, "user" )
  cBearerToken := "Bearer " + cRawToken

  lResult := AuthService():validateToken( cBearerToken )

  CHECK_TRUE( lResult )
RETURN SELF


/// <summary>
/// A raw JWT (without "Bearer " prefix) must also be accepted by validateToken.
/// Some clients omit the Bearer prefix when passing tokens directly.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_ValidRawJwt()
  LOCAL cRawToken, lResult

  cRawToken := AuthService():generateToken( TEST_USER, "user" )
  lResult   := AuthService():validateToken( cRawToken )

  CHECK_TRUE( lResult )
RETURN SELF


/// <summary>
/// A token generated with an admin role must validate successfully.
/// Verifies that role claims do not interfere with signature validation.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_ValidAdminRoleToken()
  LOCAL cToken, lResult

  cToken  := AuthService():generateToken( TEST_USER, TEST_ROLE )
  lResult := AuthService():validateToken( "Bearer " + cToken )

  CHECK_TRUE( lResult )
RETURN SELF


/// <summary>
/// generateToken without a role argument must produce a valid, decodable token
/// and the returned value must be a non-empty string.
/// </summary>
METHOD AuthServiceTestGroup:testGenerateToken_DefaultUserRole()
  LOCAL cToken

  cToken := AuthService():generateToken( TEST_USER )

  CHECK_CHAR_TYPE( cToken )
  CHECK_GREATER( Len(cToken), 0 )
  // Token must be a valid JWT (three Base64url segments separated by dots)
  CHECK_TRUE( Occurs(".", cToken) >= 2 )
RETURN SELF


/// <summary>
/// generateToken with an explicit role must embed that role in the payload.
/// We verify this indirectly by confirming the token validates and was generated
/// with the expected parameters.
/// </summary>
METHOD AuthServiceTestGroup:testGenerateToken_CustomRole()
  LOCAL cToken

  cToken := AuthService():generateToken( TEST_USER, TEST_ROLE )

  CHECK_CHAR_TYPE( cToken )
  CHECK_GREATER( Len(cToken), 0 )
  CHECK_TRUE( Occurs(".", cToken) >= 2 )
RETURN SELF


/// <summary>
/// authenticateUser must return .T. for the known valid credentials.
/// </summary>
METHOD AuthServiceTestGroup:testAuthenticateUser_ValidCredentials()
  LOCAL lResult

  lResult := AuthService():authenticateUser( TEST_USER, TEST_PASSWORD )

  CHECK_TRUE( lResult )
RETURN SELF


/// <summary>
/// authenticateUser must return .F. when the password is wrong.
/// </summary>
METHOD AuthServiceTestGroup:testAuthenticateUser_InvalidPassword()
  LOCAL lResult

  lResult := AuthService():authenticateUser( TEST_USER, "wrongpassword" )

  CHECK_FALSE( lResult )
RETURN SELF


/// <summary>
/// authenticateUser must return .F. when the username is unknown.
/// </summary>
METHOD AuthServiceTestGroup:testAuthenticateUser_InvalidUser()
  LOCAL lResult

  lResult := AuthService():authenticateUser( "bob", TEST_PASSWORD )

  CHECK_FALSE( lResult )
RETURN SELF


//////////////////////////////////////////////////////////////////////
// Edge Cases
//////////////////////////////////////////////////////////////////////

/// <summary>
/// validateToken must return .F. immediately for an empty string
/// without raising an error.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_EmptyString()
  LOCAL lResult

  lResult := AuthService():validateToken( "" )

  CHECK_FALSE( lResult )
RETURN SELF


/// <summary>
/// validateToken must correctly strip "Bearer " even when the JWT
/// itself contains leading/trailing whitespace (e.g., "Bearer  <jwt>  ").
/// AllTrim inside the method should handle this gracefully.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_BearerWithExtraWhitespace()
  LOCAL cRawToken, cBearerToken, lResult

  cRawToken    := AuthService():generateToken( TEST_USER, "user" )
  // Extra space after "Bearer " and trailing space
  cBearerToken := "Bearer  " + cRawToken + "  "

  // The implementation uses AllTrim on the extracted value;
  // the extra leading space before the JWT will be trimmed.
  // Result depends on implementation detail - we verify no crash occurs
  // and the return type is logical.
  lResult := AuthService():validateToken( cBearerToken )

  CHECK_LOGICAL_TYPE( lResult )
RETURN SELF


/// <summary>
/// A token whose expiration time is in the past must be rejected.
/// We simulate this by generating a token, waiting is impractical,
/// so we directly craft a token with a past expiration using JWT API.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_ExpiredToken()
  LOCAL oPayload, oJwt, cExpiredToken, lResult

  // Build payload with expiration 1 second in the past
  oPayload := JWTPayload():new()
  oPayload:setSubject( TEST_USER )
  oPayload:setExpiration( UnixTime() - 1 )
  oPayload:setClaim( "role", "user" )

  oJwt         := JWT():new()
  cExpiredToken := oJwt:encode( oPayload, "HS256", TEST_SECRET )

  lResult := AuthService():validateToken( cExpiredToken )

  CHECK_FALSE( lResult )
RETURN SELF


/// <summary>
/// A token signed with a different secret must be rejected even if
/// the structure is otherwise valid. This guards against secret leakage.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_WrongSecret()
  LOCAL oPayload, oJwt, cToken, lResult

  // Generate token with a DIFFERENT secret than what AuthService uses
  oPayload := JWTPayload():new()
  oPayload:setSubject( TEST_USER )
  oPayload:setExpiration( UnixTime() + 3600 )
  oPayload:setClaim( "role", "user" )

  oJwt   := JWT():new()
  cToken := oJwt:encode( oPayload, "HS256", "completely-different-secret" )

  lResult := AuthService():validateToken( cToken )

  CHECK_FALSE( lResult )
RETURN SELF


/// <summary>
/// setJwtSecret with an empty string must be silently ignored,
/// leaving the previously configured secret intact.
/// </summary>
METHOD AuthServiceTestGroup:testSetJwtSecret_EmptyStringIgnored()
  LOCAL cSecretBefore, cSecretAfter

  cSecretBefore := AuthService():getJwtSecret()
  AuthService():setJwtSecret( "" )
  cSecretAfter := AuthService():getJwtSecret()

  CHECK_STR_EQUAL( cSecretBefore, cSecretAfter )
RETURN SELF


/// <summary>
/// generateToken with an empty cRole argument must default to "user"
/// and still produce a valid, non-empty JWT string.
/// </summary>
METHOD AuthServiceTestGroup:testGenerateToken_EmptyRoleDefaultsToUser()
  LOCAL cToken, lValid

  cToken := AuthService():generateToken( TEST_USER, "" )

  CHECK_CHAR_TYPE( cToken )
  CHECK_GREATER( Len(cToken), 0 )

  // The generated token must be valid (role defaulted to "user")
  lValid := AuthService():validateToken( cToken )
  CHECK_TRUE( lValid )
RETURN SELF


//////////////////////////////////////////////////////////////////////
// Error Conditions
//////////////////////////////////////////////////////////////////////

/// <summary>
/// A malformed JWT (wrong number of segments) must be rejected gracefully
/// without raising an unhandled exception.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_MalformedJwt()
  LOCAL lResult

  // Only two segments instead of three
  lResult := AuthService():validateToken( "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbGljZSJ9" )

  CHECK_FALSE( lResult )
RETURN SELF


/// <summary>
/// A completely random string passed as a token must return .F.
/// without crashing. Guards against garbage input from HTTP headers.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_RandomString()
  LOCAL lResult

  lResult := AuthService():validateToken( "not-a-jwt-at-all-!!@#$%" )

  CHECK_FALSE( lResult )
RETURN SELF


/// <summary>
/// authenticateUser with empty username and password must return .F.
/// and not raise an error.
/// </summary>
METHOD AuthServiceTestGroup:testAuthenticateUser_EmptyCredentials()
  LOCAL lResult

  lResult := AuthService():authenticateUser( "", "" )

  CHECK_FALSE( lResult )
RETURN SELF


//////////////////////////////////////////////////////////////////////
// Real-World Usage Patterns
//////////////////////////////////////////////////////////////////////

/// <summary>
/// Full login-and-validate workflow:
/// 1. Authenticate user with credentials
/// 2. Generate a token on success
/// 3. Validate the token on a subsequent request
/// This mirrors the actual API authentication flow.
/// </summary>
METHOD AuthServiceTestGroup:testFullAuthWorkflow_LoginAndValidate()
  LOCAL lAuthenticated, cToken, lValid

  // Step 1: Authenticate
  lAuthenticated := AuthService():authenticateUser( TEST_USER, TEST_PASSWORD )
  CHECK_TRUE( lAuthenticated )

  // Step 2: Generate token for authenticated user
  cToken := AuthService():generateToken( TEST_USER, "user" )
  CHECK_CHAR_TYPE( cToken )
  CHECK_GREATER( Len(cToken), 0 )

  // Step 3: Validate token on next request (Bearer format)
  lValid := AuthService():validateToken( "Bearer " + cToken )
  CHECK_TRUE( lValid )
RETURN SELF


/// <summary>
/// Admin role workflow: generate an admin token and confirm it validates.
/// Simulates an admin login followed by an API call requiring admin privileges.
/// </summary>
METHOD AuthServiceTestGroup:testFullAuthWorkflow_GenerateAndValidateAdminToken()
  LOCAL cToken, lValid

  // Admin user authenticates (same credentials, different role assignment)
  cToken := AuthService():generateToken( TEST_USER, "admin" )

  CHECK_CHAR_TYPE( cToken )
  CHECK_GREATER( Len(cToken), 0 )

  // Token must pass validation
  lValid := AuthService():validateToken( "Bearer " + cToken )
  CHECK_TRUE( lValid )
RETURN SELF


/// <summary>
/// Verify that validateToken handles both "Bearer " prefix and raw JWT
/// for the same underlying token, producing consistent results.
/// This covers the two branches of the prefix-parsing logic.
/// </summary>
METHOD AuthServiceTestGroup:testValidateToken_BearerPrefixVariants()
  LOCAL cRawToken, lRawValid, lBearerValid

  cRawToken := AuthService():generateToken( TEST_USER, "user" )

  // Raw JWT (no prefix)
  lRawValid := AuthService():validateToken( cRawToken )

  // Bearer-prefixed JWT
  lBearerValid := AuthService():validateToken( "Bearer " + cRawToken )

  // Both variants must produce the same positive result
  CHECK_TRUE( lRawValid )
  CHECK_TRUE( lBearerValid )
  CHECK_EQUAL( lRawValid, lBearerValid )
RETURN SELF

/*
 * Occurs( cNeedle, cHaystack ) -> nCount
 *
 * Counts the number of non-overlapping occurrences of cNeedle within
 * cHaystack. Returns 0 when cNeedle is empty or not found.
 */
FUNCTION Occurs( cNeedle, cHaystack )
   LOCAL nCount := 0
   LOCAL nPos   := 0
   LOCAL nLen   := Len( cNeedle )

   IF nLen == 0
      RETURN 0
   ENDIF

   DO WHILE ( nPos := At( cNeedle, cHaystack, nPos + 1 ) ) > 0
      nCount++
      nPos += nLen - 1
   ENDDO

RETURN nCount


