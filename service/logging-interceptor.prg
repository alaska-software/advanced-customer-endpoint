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
/// Logs method entry and records the start time for elapsed-time calculation.
/// </summary>
///
/// <param name="oHandler">RestHandler instance (unused)</param>
/// <param name="cMethod">Name of the handler method about to execute</param>
/// <param name="aParams">Array of method parameters (unused)</param>
/// <returns>Self: instance reference</returns>
///
METHOD LoggingInterceptor:before( oHandler, cMethod, aParams )
  LOCAL cMsg

  UNUSED(oHandler)
  UNUSED(aParams)

  ::StartTime := Seconds()

  cMsg := "REST " + cMethod + " started"
  XppFileLogger():info( cMsg )

  // Always allow execution
  ::voteCommit()

RETURN SELF


/// <summary>
/// Logs method completion and elapsed execution time, then passes the result through.
/// </summary>
///
/// <param name="oHandler">RestHandler instance (unused)</param>
/// <param name="cMethod">Name of the completed handler method</param>
/// <param name="xResult">The method result value, passed through unchanged</param>
/// <returns>Value: xResult passed through unchanged</returns>
///
METHOD LoggingInterceptor:after( oHandler, cMethod, xResult )
  LOCAL nElapsed, cMsg

  UNUSED(oHandler)

  nElapsed := Seconds() - ::StartTime

  cMsg := "REST " + cMethod + " completed in " + ;
          AllTrim(Str(nElapsed,10,3)) + "s"

  XppFileLogger():info( cMsg )

RETURN xResult  // Pass through unchanged


/// <summary>
/// Logs error information and delegates handling to the default framework mechanism.
/// </summary>
///
/// <param name="oHandler">RestHandler instance (unused)</param>
/// <param name="cMethod">Name of the handler method that failed</param>
/// <param name="oError">Error object containing Description and other error details</param>
/// <returns>Logical: .F. to delegate error handling to the default framework mechanism</returns>
///
METHOD LoggingInterceptor:onError( oHandler, cMethod, oError )
  LOCAL cMsg

  UNUSED(oHandler)

  cMsg := "REST " + cMethod + " failed: " + oError:Description

  XppFileLogger():error( cMsg )

RETURN .F.  // Don't handle error, let default handling proceed

