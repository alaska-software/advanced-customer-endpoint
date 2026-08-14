//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Example: Authentication interceptor for REST handlers
/// </summary>
///
/// <remarks>
/// This interceptor demonstrates how to implement authentication
/// as a cross-cutting concern. It checks for a valid authorization
/// token in the request headers and aborts execution if the token
/// is missing or invalid.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "appevent.ch"
#include "common.ch"
#include "../business-logic/auth-service.ch"

CLASS AuthInterceptor FROM RestInterceptor
  EXPORTED:
  METHOD before( oHandler, cMethod, aParams )
ENDCLASS


/// <summary>
/// Validates a Bearer token before method execution using AuthService
/// </summary>
///
/// <param name="oHandler">RestHandler instance providing access to the HTTP request and setError()</param>
/// <param name="cMethod">Name of the handler method about to be executed (unused)</param>
/// <param name="aParams">Array of method parameters (unused)</param>
/// <returns>Self: instance reference</returns>
///
METHOD AuthInterceptor:before( oHandler, cMethod, aParams )
  LOCAL cAuth

  UNUSED(cMethod)
  UNUSED(aParams)

  // Expect "Authorization: Bearer <token>"
  cAuth := oHandler:HttpRequest:getHeader("Authorization")

  IF Empty(cAuth)
    oHandler:setError( 401, "Missing authorization header" )
    ::voteAbort()
    RETURN SELF
  ENDIF

  // Use AuthService to validate the token
  IF !AuthService():validateToken( cAuth )
    oHandler:setError( 401, "Invalid or expired token" )
    ::voteAbort()
    RETURN SELF
  ENDIF

  // Token is valid - allow request to proceed
  ::voteCommit()

RETURN SELF

