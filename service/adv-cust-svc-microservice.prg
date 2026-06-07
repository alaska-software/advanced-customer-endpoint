//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// add your summary
/// </summary>
///
///
/// <remarks>
/// </remarks>
///
///
/// <todo>
/// </todo>
///
/// <copyright>
/// 
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


CLASS METHOD AdvCustSvc:beforeRun(aParameters)
  // $TODO add your code here which you want to be executed before your service starts
RETURN SUPER:beforeRun(aParameters)


CLASS METHOD AdvCustSvc:afterRun()
  // $TODO add your code here
RETURN SUPER:afterRun()


CLASS METHOD AdvCustSvc:onRestart(oState)
  UNUSED(oState)
  XppRtFileLogger():warning(FormatMessage("Processing restart for(%1)",::classname()))

  // $TODO add your code here
RETURN SELF


CLASS METHOD AdvCustSvc:onRecover(oState)
  UNUSED(oState)
  XppRtFileLogger():warning(FormatMessage("Processing recover for(%1)",::classname()))

  /// add your code which is a last resort. repeated restarts failed
RETURN SELF

CLASS METHOD AdvCustSvc:onReady()
  /// $TODO add your code here 
RETURN SELF
