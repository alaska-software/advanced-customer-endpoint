//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Example: Logging interceptor for REST handlers
/// </summary>
///
/// <remarks>
/// This interceptor demonstrates how to implement logging as a
/// cross-cutting concern. It logs method entry, exit, execution time,
/// and errors.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "appevent.ch"
#include "common.ch"

CLASS LoggingInterceptor FROM RestInterceptor
  PROTECTED:
  VAR StartTime

  EXPORTED:
  METHOD before( oHandler, cMethod, aParams )
  METHOD after( oHandler, cMethod, xResult )
  METHOD onError( oHandler, cMethod, oError )
ENDCLASS


/// <summary>
/// Logs method entry and records start time
/// </summary>
///
METHOD LoggingInterceptor:before( oHandler, cMethod, aParams )
  LOCAL cMsg

  UNUSED(oHandler)
  UNUSED(aParams)

  ::StartTime := Seconds()

  cMsg := "REST " + cMethod + " started"
  XppRtFileLogger():info( cMsg )

  // Always allow execution
  ::voteCommit()

RETURN SELF


/// <summary>
/// Logs method completion and execution time
/// </summary>
///
METHOD LoggingInterceptor:after( oHandler, cMethod, xResult )
  LOCAL nElapsed, cMsg

  UNUSED(oHandler)

  nElapsed := Seconds() - ::StartTime

  cMsg := "REST " + cMethod + " completed in " + ;
          AllTrim(Str(nElapsed,10,3)) + "s"

  XppRtFileLogger():info( cMsg )

RETURN xResult  // Pass through unchanged


/// <summary>
/// Logs error information
/// </summary>
///
METHOD LoggingInterceptor:onError( oHandler, cMethod, oError )
  LOCAL cMsg

  UNUSED(oHandler)

  cMsg := "REST " + cMethod + " failed: " + oError:Description

  XppRtFileLogger():error( cMsg )

RETURN .F.  // Don't handle error, let default handling proceed
