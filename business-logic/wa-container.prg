//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// This workarea container serves two distinct purposes:
/// - It encapsulates the workarea resources such as tables and orders and
///   simplifies/unifies WA data access by means of open/close operations.
/// - It is a stateless container, meaning we do not care about any state
///   of the workarea. We only care about the currently active workarea and
///   ensure that after open, the current area holds the table with orders,
///   and that close restores the previously active workarea.
/// </summary>
///
/// <remarks>
/// The main benefit of this implementation is the performance gain achieved by
/// using DbRelease()/DbRequest() instead of repeatedly performing
/// DbeUseArea/DbCloseArea operations for accessing tables and orders. This means
/// the workarea is released to the zero workspace, allowing another thread to
/// grab the ready-to-use workarea at no cost.
/// <para/>
/// In this way, the WAContainer saves significant overhead in a multithreaded
/// stateless implementation. It is therefore a perfect fit for service
/// or web handler workloads.
/// <para/>
/// WAContainer is scheduled to be included in the multi-threading helper asset
/// before final product release.
/// </remarks>
///
///
/// <copyright>
/// Alaska Software Inc., 2025. All Rights Reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

CLASS WAContainer
  PROTECTED:
  VAR _Workarea
  VAR _WorkareaStack
  CLASS VAR _Prototype

  METHOD createDataObject()
  METHOD pushWorkarea()
  METHOD popWorkarea()
  EXPORTED:
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
  DEFERRED METHOD toWorkarea()
  DEFERRED METHOD fromWorkarea()
  EXPORTED:
  DEFERRED CLASS METHOD use()
  METHOD getDefault()
ENDCLASS


/// <summary>
/// Creates a data container based on the prototype definition
/// </summary>
///
METHOD WAContainer:createDataObject()
  IF IsNull(::_Prototype)
     ::setupPrototype()
  ENDIF
RETURN ::_Prototype:copy()


/// <summary>
/// push/popWorkarea implements a simple workarea stack. This simplifies workarea
/// handling as it allows us to easily and consistently ensure the caller's current
/// workarea stays untouched.
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
/// open first checks if the workarea is already open in the zero workspace
/// and tries to request it. Only if the request fails does it use a new one. This
/// way we can avoid repeated USE operations and instead play ping-pong between
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
/// close first tries to release the workarea to the zero workspace
/// instead of closing it. If that was successful, another thread can grab
/// that WA, so we do not need to close it.
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



