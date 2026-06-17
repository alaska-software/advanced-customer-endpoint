
//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Authentication Service using JWT validation
/// </summary>
///
/// <remarks>
/// This service validates JWT tokens signed with HS256.
/// The signing secret must match the one used in login-endpoint.prg.
/// In production, load the secret from configuration-manager.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "common.ch"
#include "auth-service.ch"

CLASS AuthService
  PROTECTED:
  CLASS VAR _cJwtSecret INIT AUTH_SECRET

  EXPORTED:
  CLASS METHOD setJwtSecret( cSecret )
  CLASS METHOD validateToken( cToken )
  CLASS METHOD getJwtSecret()
ENDCLASS


/// <summary>
/// Set the JWT signing secret (optional - for testing)
/// </summary>
///
CLASS METHOD AuthService:setJwtSecret( cSecret )
  IF !Empty(cSecret)
    ::_cJwtSecret := cSecret
  ENDIF
RETURN


/// <summary>
/// Get the JWT signing secret (for testing purposes)
/// </summary>
///
CLASS METHOD AuthService:getJwtSecret()
RETURN ::_cJwtSecret


/// <summary>
/// Validate a JWT authorization token
/// </summary>
/// <param name="cToken">The authorization token (e.g., "Bearer <jwt>")</param>
/// <returns>Logical - .T. if valid, .F. otherwise</returns>
///
CLASS METHOD AuthService:validateToken( cToken )
  LOCAL cTokenValue, oJwt, oPayload

  IF Empty(cToken)
    RETURN .F.
  ENDIF

  // Parse token format: "Bearer <jwt>" or just "<jwt>"
  IF "Bearer " $ cToken
    cTokenValue := SubStr(cToken, At("Bearer ", cToken) + 7)
  ELSE
    cTokenValue := cToken
  ENDIF

  // Trim whitespace
  cTokenValue := AllTrim(cTokenValue)

  // Decode and verify JWT
  oJwt := JWT():new()
  oPayload := oJwt:decode( cTokenValue, "HS256", ::_cJwtSecret )

  // If decode fails or token is expired, oPayload will be NIL
  IF oPayload == NIL
    RETURN .F.
  ENDIF

  // Check expiration
  IF oPayload:isExpired()
    RETURN .F.
  ENDIF

RETURN .T.
