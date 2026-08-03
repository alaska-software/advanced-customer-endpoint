//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Advanced Customer Service microservice lifecycle implementation
/// </summary>
///
/// <remarks>
/// Extends the Microservice base class to provide lifecycle hooks for
/// the Advanced Customer Service. Implement beforeRun / afterRun for
/// startup and shutdown logic, and onRestart / onRecover / onReady for
/// resilience and recovery scenarios.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "common.ch"

CLASS AdvCustSvc FROM Microservice
  EXPORTED:
  CLASS METHOD beforeRun()
  CLASS METHOD afterRun()

  CLASS METHOD onRestart()
  CLASS METHOD onRecover()
  CLASS METHOD onReady()
ENDCLASS


/// <summary>
/// Called by the framework before the service run loop starts.
/// Use this hook to perform one-time initialisation (e.g. open connections,
/// register handlers, load configuration).
/// </summary>
///
/// <param name="aParameters">Array of command-line parameter strings</param>
/// <returns>Logical: result of the base-class beforeRun()</returns>
///
CLASS METHOD AdvCustSvc:beforeRun(aParameters)
  // $TODO add your code here which you want to be executed before your service starts
RETURN SUPER:beforeRun(aParameters)


/// <summary>
/// Called by the framework after the service run loop ends.
/// Use this hook to release resources acquired in beforeRun().
/// </summary>
///
/// <returns>Logical: result of the base-class afterRun()</returns>
///
CLASS METHOD AdvCustSvc:afterRun()
  // $TODO add your code here
RETURN SUPER:afterRun()


/// <summary>
/// Called by the framework when the service is being restarted after a failure.
/// Use this hook to reset transient state before the next run attempt.
/// </summary>
///
/// <param name="oState">Recovery state object provided by the framework</param>
/// <returns>Self: class reference</returns>
///
CLASS METHOD AdvCustSvc:onRestart(oState)
  UNUSED(oState)
  XppRtFileLogger():warning(FormatMessage("Processing restart for(%1)",::classname()))

  // $TODO add your code here
RETURN SELF


/// <summary>
/// Called by the framework as a last resort when repeated restarts have failed.
/// Use this hook to perform emergency cleanup or alerting.
/// </summary>
///
/// <param name="oState">Recovery state object provided by the framework</param>
/// <returns>Self: class reference</returns>
///
CLASS METHOD AdvCustSvc:onRecover(oState)
  UNUSED(oState)
  XppRtFileLogger():warning(FormatMessage("Processing recover for(%1)",::classname()))

  // Enforce recover state reset
RETURN .T.


/// <summary>
/// Called by the framework once the service is fully started and ready to
/// accept requests. Use this hook for post-startup notifications or health checks.
/// </summary>
///
/// <returns>Self: class reference</returns>
///
CLASS METHOD AdvCustSvc:onReady()
  // $TODO add your code here
RETURN SELF
