//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Simplified Authentication Service using API Key validation
/// </summary>
///
/// <remarks>
/// This is a simplified implementation for demonstration purposes.
/// Uses a hard-coded API key to validate authorization headers.
/// This example focuses on demonstrating the interceptor pattern,
/// not production-grade security.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "common.ch"

CLASS AuthService
  PROTECTED:
  CLASS VAR _cValidApiKey INIT "demo-api-key-12345"

  EXPORTED:
  CLASS METHOD setApiKey( cKey )
  CLASS METHOD validateToken( cToken )
  CLASS METHOD getValidApiKey()
ENDCLASS


/// <summary>
/// Set the valid API key (optional - for testing)
/// </summary>
///
CLASS METHOD AuthService:setApiKey( cKey )
  IF !Empty(cKey)
    ::_cValidApiKey := cKey
  ENDIF
RETURN


/// <summary>
/// Get the valid API key (for testing purposes)
/// </summary>
///
CLASS METHOD AuthService:getValidApiKey()
RETURN ::_cValidApiKey


/// <summary>
/// Validate an authorization token against hard-coded API key
/// </summary>
/// <param name="cToken">The authorization token (e.g., "Bearer demo-api-key-12345")</param>
/// <returns>Logical - .T. if valid, .F. otherwise</returns>
///
CLASS METHOD AuthService:validateToken( cToken )
  LOCAL cTokenValue

  IF Empty(cToken)
    RETURN .F.
  ENDIF

  // Parse token format: "Bearer <api-key>" or just "<api-key>"
  IF "Bearer " $ cToken
    cTokenValue := SubStr(cToken, At("Bearer ", cToken) + 7)
  ELSE
    cTokenValue := cToken
  ENDIF

  // Trim whitespace
  cTokenValue := AllTrim(cTokenValue)

  // Simple comparison with hard-coded API key
RETURN (cTokenValue == ::_cValidApiKey)
