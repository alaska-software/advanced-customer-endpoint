//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// This experimental workarea container serves two distinct purposes.
/// - it encapsulates the workarea resorces such as tables and orders and
///   simplifies / unifies WA data access in means of open/close operation.
/// - Tt is a stateless container, meaning we do not care about any state
///   of the workarea, we only care about the current active workkarea and
///   ensure that after open the current area holds the table with orders
///   and a close does restore the previous active workarea.
/// </summary>
///
/// <remarks>
/// The point with that implementation is the performance gain due to the
/// fact that instead of permanently performing a DbeUseArea/DbCloseArea
/// operation for accessing tables and orders the WAContainer uses
/// DbRelease()/DbRequest(). Meaning, the used workarea is released to
/// the zero workspace and another thread can grab that ready to use
/// workarea at no cost.
/// <para/>
/// That way the WAContainer saves us a lot of workload in a multithreaded
/// stateless implementation. It is therefore a perfect fit for a service
/// or web handler and its workloads.
/// </remarks>
///
///
/// <copyright>
/// Alaska Software Inc., 2023. All Rights Reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

CLASS WAContainer
  PROTECTED:
  VAR _Workarea
  VAR _WorkareaStack
  CLASS VAR _Prototype

  METHOD createDataObject()
  EXPORTED:
  METHOD pushWorkarea()
  METHOD popWorkarea()

  CLASS METHOD open()
  METHOD init()
  METHOD close()

  /// <summary>
  /// Overwrite the following methods to adapt the workarea container
  /// to your needs.
  /// </summary>
  ///
  PROTECTED:
  DEFERRED METHOD setupPrototype()
  EXPORTED:
  DEFERRED METHOD toWorkarea()
  DEFERRED METHOD fromWorkarea()
  DEFERRED CLASS METHOD use()
  METHOD getDefault()
  METHOD tryRecordLock()
  METHOD doRecordUnlock
ENDCLASS


/// <summary>
/// Creates an data container based on the prototype definition
/// </summary>
///
METHOD WAContainer:createDataObject()
  IF IsNull(::_Prototype)
     ::setupPrototype()
  ENDIF
RETURN ::_Prototype:copy()


/// <summary>
/// push/popWorkarea Implements a simple workarea stack, this simplifies workarea
/// handling as it allows easily and consistently to ensure callers current workarea
/// stays untouched.
/// </summary>
///
METHOD WAContainer:pushWorkarea()
   IF IsNull(::_WorkareaStack)
     ::_WorkareaStack := {}
   ENDIF
   AAdd( ::_WorkareaStack, Select() )
   DbSelectArea( ::_Workarea )
RETURN SELF

METHOD WAContainer:popWorkarea()
  IF Empty(::_WorkareaStack)
    RETURN SELF
  ENDIF
  DbSelectArea( ATail( ::_WorkareaStack ) )
  ARemove( ::_WorkareaStack, Len( ::_WorkareaStack ) )
RETURN SELF


/// <summary>
/// open does first check if the workarea is already open in a zero workspace
/// and tries to request it. Only if the request fails it use a new one. That way
/// we can avoid repeated USE operations and instead can play ping pong between
/// threads.
/// </summary>
///
CLASS METHOD  WAContainer:open(cAlias, cStatus)
  LOCAL oWAC
  LOCAL nOldArea := Select()
  DbSelectArea(0)
  cStatus := "failed"
  IF !DbRequest(cAlias)
     ::use()
     IF Used()
       oWAC := ::new( Select() )
       cStatus := "use"
     ENDIF
  ELSE
    oWAC := ::new( Select() )
    cStatus := "request"
  ENDIF
  DbSelectArea( nOldArea )
RETURN oWAC


METHOD  WAContainer:init(nArea)
  ::_Workarea := nArea
  ::_WorkareaStack := {}
RETURN

/// <summary>
/// close does first try to release to workarea to the zero workspace
/// instead of closing it. If that was successfull another thread can grab
/// that WA so we do not need to close.
/// </summary>
///
METHOD  WAContainer:close( cStatus )
  LOCAL oE
  ::pushWorkarea()
  DbSelectArea( ::_Workarea )
  BEGIN TRY
    DbRelease()
    cStatus := "release"
  RECOVER USING oE
    DbCloseArea()
    cStatus := "close"
  END
  DbSelectArea( 0 )
  ::_Workarea      := NIL
  ::_WorkareaStack := {}
  ::popWorkarea()
RETURN SELF

/// <summary>
/// Creates a default DO
/// </summary>
///
METHOD WAContainer:getDefault()
RETURN ::createDataObject()

METHOD WAContainer:tryRecordLock()
  LOCAL nRetry := 100
  DO WHILE !(::_Workarea)->(DbRLock()) .AND. nRetry>0
    nRetry--
    Sleep(0)
  ENDDO
  IF nRetry==0
    XppRtFileLogger():error("WAContainer failed to aquire record lock for:"+ (::_Workarea)->(Alias()))
    RETURN .F.
  ENDIF
RETURN .T.

METHOD WAContainer:doRecordUnlock()
  (::_Workarea)->(DbRUnLock())
RETURN .T.



