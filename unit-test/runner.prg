//////////////////////////////////////////////////////////////////////
/// <summary>
/// Test runner - executes all test suites.
/// Hierarchy: Runner -> Suite -> Group -> Test -> Asserts
/// </summary>
///
/// <copyright>
/// Alaska Software, (c) 2026. All rights reserved.
/// </copyright>
//////////////////////////////////////////////////////////////////////


/// <summary>
/// No UI - stdout only. Additional output via test or suite.
/// </summary>
///
PROCEDURE appsys
RETURN


/// <summary>
/// Searches for custom test suites, falls back to automated suite
/// that discovers all groups/tests bound to this process.
/// </summary>
///
/// <remarks>
/// Custom suites control group execution order - useful when testing
/// basic features before complex ones that depend on them.
/// </remarks>
///
PROCEDURE MAIN()
  LOCAL oSuite
  LOCAL oListener
  LOCAL oCB
  LOCAL aSuites
  LOCAL n, aP

  SET CHARSET TO ANSI
  DbeLoad("foxdbe")
  DbeLoad("cdxdbe")
  DbeBuild("foxcdx","foxdbe","cdxdbe")

  oListener := ConsoleListener():New()

  aP := Array( PCount() )
  FOR n:=1 TO PCount()
    aP[n] := PValue(n)
  NEXT n
  CommandLineFlags():setup(aP, oListener)
  aSuites   := QuerySuites()

  IF(Empty(aSuites))
    aSuites := { AutomatedTestSuite() }
  ENDIF

  oCB := ErrorBlock({|oE|_Break(oE)})
  BEGIN SEQUENCE
    FOR n:=1 TO Len(aSuites)
      oSuite := aSuites[n]:New(CommandLineFlags(), oListener)
      oSuite:Run()
    NEXT n
  END SEQUENCE
  ErrorBlock(oCB)

  IF(oListener:isFatal())
    ErrorLevel(2)
  ELSEIF(oListener:isFailed())
    ErrorLevel(1)
  ENDIF
  oListener:Report()
RETURN
