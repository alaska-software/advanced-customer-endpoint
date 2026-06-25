//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Authentication REST Handler - Issues JWT tokens for valid credentials
/// </summary>
///
/// <remarks>
/// This handler provides a RESTful login endpoint that authenticates users
/// and issues JWT tokens. The token can then be used with the Bearer
/// authentication scheme on protected endpoints.
///
/// Flow:
///   POST /auth/login   {"user":"alice","password":"secret"}
///     -> 200 {"error":null,"result":{"token":"<jwt>","tokenType":"Bearer","expiresIn":3600}}
///
/// The signing secret is managed by AuthService and must match the secret
/// used by AuthInterceptor for token validation.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "common.ch"
#include "../business-logic/auth-service.ch"

CLASS AuthHandler FROM RestHandler
  EXPORTED:
  CLASS METHOD onRegister( oEndpoint )
  METHOD login( oCredentials )
ENDCLASS


/// <summary>
/// Register authentication routes on the endpoint
/// </summary>
///
CLASS METHOD AuthHandler:onRegister( oEndpoint )
  // POST body (application/json) arrives as a DataObject
  ::addType( "credentials", "O" )
  ::setResultMode( "envelope" )

  // Register login endpoint
  ::map( "POST", "/auth/login", "login" )
  
  UNUSED(oEndpoint)
RETURN SELF


/// <summary>
/// Authenticates the user and returns a signed JWT on success
/// </summary>
/// <param name="oCredentials">DataObject with user and password fields</param>
/// <returns>DataObject with token, tokenType, and expiresIn fields</returns>
///
METHOD AuthHandler:login( oCredentials )
  LOCAL oResult, cToken

  // Validate request body
  IF ValType(oCredentials) != "O" .OR. Empty(oCredentials:user) .OR. Empty(oCredentials:password)
    ::setError( 400, "user and password are required" )
    RETURN NIL
  ENDIF

  // Authenticate using AuthService
  IF !AuthService():authenticateUser( oCredentials:user, oCredentials:password )
    ::setError( 401, "Invalid credentials" )
    RETURN NIL
  ENDIF

  // Generate JWT token
  cToken := AuthService():generateToken( oCredentials:user, "user" )

  // Build response
  oResult := DataObject():new()
  oResult:token     := cToken
  oResult:tokenType := "Bearer"
  oResult:expiresIn := TOKEN_TTL

RETURN oResult
