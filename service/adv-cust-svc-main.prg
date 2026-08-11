//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Service entry point for the Advanced Customer Service
/// </summary>
///
/// <remarks>
/// Configures and processes command-line arguments for service control
/// (start, stop, install, uninstall), recovery manager commands, and
/// the primary run modes (exe / svc). Delegates all actual service
/// logic to the AdvCustSvc microservice class.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "Common.ch"


/// <summary>
/// Loads and builds the database engine drivers before Main() is called.
/// Invoked automatically by the Xbase++ runtime.
/// </summary>
///
PROCEDURE DbeSys()
  DbeLoad("foxdbe")
  DbeLoad("cdxdbe")
  DbeBuild("FOXCDX","FOXDBE","CDXDBE")
RETURN


/// <summary>
/// Parses command-line arguments, registers service and run-mode options,
/// starts up the service, and processes the requested action.
/// </summary>
///
PROCEDURE Main
  LOCAL n, aParameters
  LOCAL cServiceName
  LOCAL oCmd, oGrp

  SET CHARSET TO ANSI

  // pack all parameters into an array
  aParameters := Array( PCount() )
  FOR n:=1 TO PCount()
    aParameters[n]:=PValue(n)
  NEXT n


  XppFileLogger():startup()
  cServiceName := ConfigManager():Application:Service:Name

  // add generic service-command options
  oCmd := ArgumentProcessor():addCommand("service")
  oCmd:addOption("user:","user account under which service runs",{|cUser|WscAdapter():setUser( cUser )},100)
  oCmd:addOption("password:","password of user account",{|cPwd|WscAdapter():setPassword( cPwd )},100)
  oCmd:addOption("status","service status details",{||WscAdapter():status( cServiceName )} )

  // add service control option group
  oGrp := oCmd:addGroup("action")
  oGrp:addOption("start","start service",{||WscAdapter():start(cServiceName)} )
  oGrp:addOption("stop","stop service",{||WscAdapter():stop(cServiceName)} )
  oGrp:addOption("install","install service",{||WscAdapter():install( cServiceName )} )
  oGrp:addOption("uninstall","uninstall service",{||WscAdapter():uninstall( cServiceName )} )

  // recover manager comman options setup
  oCmd := ArgumentProcessor():addCommand("rm")
  oCmd:addOption("reset","reset state",{||RMAdapter():reset( AdvCustSvc() )} )
  oCmd:addOption("recover","run recovery only",{||RMAdapter():recovery( AdvCustSvc() )} )

  // primary usage option group
  oGrp := ArgumentProcessor():addGroup("run")
  oGrp:addOption("exe","run as console process",{||AdvCustSvc():runAsConsoleProcess()})
  oGrp:addOption("svc","run service process",{||AdvCustSvc():runAsServiceProcess()})

  IF !AdvCustSvc():startup(aParameters)
     RETURN
  ENDIF

  ArgumentProcessor():process( aParameters )

  IF !AdvCustSvc():shutdown()
    RETURN
  ENDIF
RETURN


 /// <summary>
 /// Application system procedure. No-op — UI initialisation is suppressed
 /// for headless service operation.
 /// </summary>
 ///
 PROCEDURE AppSys
 RETURN

