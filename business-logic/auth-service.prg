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
  CLASS VAR _JwtSecret

  EXPORTED:
  CLASS METHOD initClass()
  CLASS METHOD setJwtSecret( cSecret )
  CLASS METHOD validateToken( cToken )
  CLASS METHOD getJwtSecret()
  CLASS METHOD authenticateUser( cUser, cPassword )
  CLASS METHOD generateToken( cUser, cRole )
ENDCLASS


/// <summary>
/// Initialize class-level defaults
/// </summary>
///
/// <returns>Self: class reference after initialization</returns>
///
CLASS METHOD AuthService:initClass()
  ::_JwtSecret := AUTH_SECRET
RETURN SELF


/// <summary>
/// Set the JWT signing secret (optional - for testing)
/// </summary>
///
/// <param name="cSecret">New JWT signing secret; ignored if empty</param>
///
CLASS METHOD AuthService:setJwtSecret( cSecret )
  IF !Empty(cSecret)
    ::_JwtSecret := cSecret
  ENDIF
RETURN


/// <summary>
/// Get the JWT signing secret (for testing purposes)
/// </summary>
///
/// <returns>String: the current JWT signing secret</returns>
///
CLASS METHOD AuthService:getJwtSecret()
RETURN ::_JwtSecret


/// <summary>
/// Validate a JWT authorization token
/// </summary>
///
/// <param name="cToken">The authorization token (e.g., "Bearer <jwt>")</param>
/// <returns>Logical: .T. if valid, .F. otherwise</returns>
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

  // verify JWT
  oJwt := JWT():new()
  IF !oJwt:verify( cTokenValue, ::_JwtSecret )
    RETURN .F.
  ENDIF

  IF !oJwt:decode( cTokenValue )
    RETURN .F.
  ENDIF

  oPayload := oJwt:getPayload()
  IF oPayload:isExpired()
    RETURN .F.
  ENDIF
RETURN .T.


/// <summary>
/// Authenticate a user with credentials
/// </summary>
///
/// <param name="cUser">Username</param>
/// <param name="cPassword">Password</param>
/// <returns>Logical: .T. if credentials are valid, .F. otherwise</returns>
///
CLASS METHOD AuthService:authenticateUser( cUser, cPassword )
  // Demo implementation - accepts hard-coded user
  // Replace with real authentication (database lookup, password hash comparison, etc.)
RETURN cUser == "alice" .AND. cPassword == "secret"


/// <summary>
/// Generate a JWT token for an authenticated user
/// </summary>
///
/// <param name="cUser">Username (subject)</param>
/// <param name="cRole">User role (optional, defaults to "user")</param>
/// <returns>String: signed JWT token</returns>
///
CLASS METHOD AuthService:generateToken( cUser, cRole )
  LOCAL oPayload, oJwt, cToken

  IF Empty(cRole)
    cRole := "user"
  ENDIF

  // Build the JWT payload with claims
  oPayload := JWTPayload():new()
  oPayload:setSubject( cUser )
  oPayload:setExpiration( UnixTime() + TOKEN_TTL )
  oPayload:setClaim( "role", cRole )

  // Encode and sign the token
  oJwt := JWT():new()
  cToken := oJwt:encode( oPayload, "HS256", ::_JwtSecret )

RETURN cToken
