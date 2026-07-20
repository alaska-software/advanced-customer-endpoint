//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Stateless workarea container base class
/// </summary>
///
/// <remarks>
/// This experimental workarea container serves two distinct purposes:
/// it encapsulates the workarea resources such as tables and orders and
/// simplifies / unifies WA data access in means of open/close operation;
/// and it is a stateless container, meaning we do not care about any state
/// of the workarea - we only care about the current active workarea and
/// ensure that after open the current area holds the table with orders,
/// and that close restores the previous active workarea.
/// <para/>
/// The performance gain comes from using DbRelease()/DbRequest() instead
/// of permanently performing DbeUseArea/DbCloseArea operations. The used
/// workarea is released to the zero workspace so another thread can grab
/// that ready-to-use workarea at no cost. This makes WAContainer a perfect
/// fit for multithreaded stateless service and web handler workloads.
/// </remarks>
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
  CLASS METHOD shutdown()

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
/// Creates a data object based on the prototype definition.
/// Calls setupPrototype() lazily on first use.
/// </summary>
///
/// <returns>Object: new DataObject populated from the prototype</returns>
///
METHOD WAContainer:createDataObject()
  IF IsNull(::_Prototype)
     ::setupPrototype()
  ENDIF
RETURN ::_Prototype:copy()


/// <summary>
/// Saves the current workarea to an internal stack and activates this container's workarea.
/// Use together with popWorkarea() to ensure the caller's active workarea is preserved.
/// </summary>
///
/// <returns>Self: instance reference for fluent chaining</returns>
///
METHOD WAContainer:pushWorkarea()
   IF IsNull(::_WorkareaStack)
     ::_WorkareaStack := {}
   ENDIF
   AAdd( ::_WorkareaStack, Select() )
   DbSelectArea( ::_Workarea )
RETURN SELF


/// <summary>
/// Restores the workarea that was active before the last pushWorkarea() call.
/// </summary>
///
/// <returns>Self: instance reference for fluent chaining</returns>
///
METHOD WAContainer:popWorkarea()
  IF Empty(::_WorkareaStack)
    RETURN SELF
  ENDIF
  DbSelectArea( ATail( ::_WorkareaStack ) )
  ARemove( ::_WorkareaStack, Len( ::_WorkareaStack ) )
RETURN SELF


/// <summary>
/// Opens the workarea for this container. First checks whether the workarea is already
/// available in the zero workspace and tries to request it. Only if the request fails
/// does it call use() to open a fresh workarea. This avoids repeated USE operations
/// and allows workareas to be exchanged between threads.
/// </summary>
///
/// <param name="cAlias">Workarea alias to request from the zero workspace (optional)</param>
/// <param name="cStatus">Output: receives "request", "use", or "failed" describing how the workarea was acquired</param>
/// <returns>Object: WAContainer instance for the opened workarea, or NIL on failure</returns>
///
CLASS METHOD  WAContainer:open(cAlias, cStatus)
  LOCAL oWAC
  LOCAL nOldArea := Select()
  DbSelectArea(0)
  cStatus := "failed"
  IF !DbRequest(cAlias)
     ::use(cAlias)
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


/// <summary>
/// Initializes the container instance with the given workarea number.
/// </summary>
///
/// <param name="nArea">Workarea number to associate with this container instance</param>
/// <returns>Self: instance reference</returns>
///
METHOD  WAContainer:init(nArea)
  ::_Workarea := nArea
  ::_WorkareaStack := {}
RETURN


/// <summary>
/// Releases the workarea back to the zero workspace so another thread can reuse it.
/// Falls back to DbCloseArea() if DbRelease() fails.
/// </summary>
///
/// <param name="cStatus">Output: receives "release" or "close" describing how the workarea was freed</param>
/// <returns>Self: instance reference</returns>
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
/// Returns a default DataObject pre-populated with empty field values
/// as defined by the prototype.
/// </summary>
///
/// <returns>Object: default DataObject for this workarea</returns>
///
METHOD WAContainer:getDefault()
RETURN ::createDataObject()


/// <summary>
/// Attempts to acquire a record lock on the current workarea record,
/// retrying up to 100 times with brief sleeps between attempts.
/// Logs an error if the lock cannot be acquired.
/// </summary>
///
/// <returns>Logical: .T. if the record lock was acquired, .F. on timeout</returns>
///
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


/// <summary>
/// Releases the record lock on the current workarea record.
/// </summary>
///
/// <returns>Logical: .T. always</returns>
///
METHOD WAContainer:doRecordUnlock()
  (::_Workarea)->(DbRUnLock())
RETURN .T.


CLASS METHOD  WAContainer:shutdown(cAlias)
  DO WHILE DbRequest(cAlias)
    DbCloseArea()
  ENDDO
RETURN SELF
