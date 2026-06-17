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
/// Validates a Bearer JWT before method execution
/// </summary>
///
/// <remarks>
/// Two independent checks are required:
///   1. :verify()  - the signature must match our secret (token untampered).
///   2. :decode() + getPayload():isValid() - the token must still be within
///      its time window (exp / nbf). NOTE: :verify() does NOT check expiration,
///      so an expired-but-correctly-signed token passes step 1 and must be
///      rejected by step 2.
/// </remarks>
///
METHOD AuthInterceptor:before( oHandler, cMethod, aParams )
  LOCAL cAuth, cToken, oJWT

  UNUSED(cMethod)
  UNUSED(aParams)

  // Expect "Authorization: Bearer <token>"
  cAuth := oHandler:HttpRequest:getHeader("Authorization")

  IF Empty(cAuth) .OR. Upper(Left(cAuth, 7)) != "BEARER "
    oHandler:setError( 401, "Missing or malformed authorization header" )
    ::voteAbort()
    RETURN SELF
  ENDIF

  cToken := AllTrim( SubStr(cAuth, 8) )

  oJWT := JWT():new()

  // 1) Signature must verify against our shared secret.
  //    A tampered token - or an "alg":"none" token - fails here.
  IF !oJWT:verify( cToken, AUTH_SECRET )
    oHandler:setError( 401, "Invalid token signature" )
    ::voteAbort()
    RETURN SELF
  ENDIF

  // 2) Token must decode and still be within its exp / nbf window.
  IF !oJWT:decode( cToken ) .OR. !oJWT:getPayload():isValid()
    oHandler:setError( 401, "Expired or not-yet-valid token" )
    ::voteAbort()
    RETURN SELF
  ENDIF

  // Token is valid. The caller's identity is available as
  //   oJWT:getPayload():getSubject()
  // RestHandler currently has no setUser() hook to forward it to the
  // business method; if you need the identity downstream, expose one on
  // your handler (or stash it on the request) here.

  ::voteCommit()

RETURN SELF
