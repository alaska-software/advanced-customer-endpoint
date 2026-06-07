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

CLASS AuthInterceptor FROM RestInterceptor
  EXPORTED:
  METHOD before( oHandler, cMethod, aParams )
ENDCLASS


/// <summary>
/// Validates authentication before method execution
/// </summary>
///
METHOD AuthInterceptor:before( oHandler, cMethod, aParams )
  LOCAL cToken, lValid

  UNUSED(cMethod)
  UNUSED(aParams)

  // Get authorization header
  cToken := oHandler:HttpRequest:getHeader("Authorization")

  IF Empty(cToken)
    oHandler:setError( 401, "Missing authorization token" )
    ::voteAbort()
    RETURN SELF
  ENDIF

  // Validate token (simplified - in real implementation, verify signature, expiration, etc.)
  lValid := AuthService():validateToken( cToken )

  IF !lValid
    oHandler:setError( 401, "Invalid or expired authorization token" )
    ::voteAbort()
    RETURN SELF
  ENDIF

  // Token is valid - allow execution
  ::voteCommit()

RETURN SELF
