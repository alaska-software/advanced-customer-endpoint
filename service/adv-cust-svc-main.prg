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

#include "Common.ch"

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


  XppRtFileLogger():startup()
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

PROCEDURE AppSys
RETURN
