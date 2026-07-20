//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Workarea Container for the customer.dbf table
/// </summary>
///
/// <remarks>
/// Concrete WAContainer subclass for the customer table.
/// Handles table open/close, field mapping, and timestamp maintenance
/// (created and modified) transparently in toWorkarea().
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////
#include "foxdbe.ch"
#include "cdxdbe.ch"

CLASS WACCustomer FROM WAContainer
  PROTECTED:
  CLASS VAR _Path
  CLASS METHOD use()
  METHOD setupPrototype()
  EXPORTED:
  CLASS METHOD setPath()
  CLASS METHOD shutdown()
  METHOD fromWorkarea()
  METHOD toWorkarea()
ENDCLASS


/// <summary>
/// Sets the file-system path used when opening the customer table.
/// </summary>
///
/// <param name="cPath">Path to the directory containing customer.dbf and customer.cdx</param>
/// <returns>Self: class reference for fluent chaining</returns>
///
CLASS METHOD WACCustomer:setPath(cPath)
  ::_Path := cPath
RETURN SELF

CLASS METHOD WACCustomer:shutdown()
  SUPER:shutdown("customer")
RETURN SELF

/// <summary>
/// Opens the customer table with its compound index file.
/// Resolves the path from ConfigManager when no explicit path has been set via setPath().
/// </summary>
///
/// <returns>Self: class reference</returns>
///
CLASS METHOD WACCustomer:use()
  LOCAL cPath, oNode

  IF IsNull(::_Path)
    oNode := ConfigManager():binary
    IF IsNull(oNode)
      XppRtFileLogger():error("No node application config file")
      RETURN SELF
    ENDIF
    oNode := oNode:path
    IF IsNull(oNode)
      XppRtFileLogger():error("No path node in application config file")
      RETURN SELF
    ENDIF
    cPath := oNode:customer
    IF IsNull(cPath)
      XppRtFileLogger():error("No customer attrib in path node in application config file")
      RETURN SELF
    ENDIF
  ELSE
    cPath := ::_Path
  ENDIF

  // Open customer.dbf with customer.cdx compound index
  USE (cPath+"customer.dbf") INDEX (cPath+"customer.cdx") NEW ALIAS customer
RETURN SELF


/// <summary>
/// Sets up the prototype DataObject with all customer fields and their empty default values.
/// Called lazily on first use via WAContainer:createDataObject().
/// </summary>
///
/// <returns>Self: instance reference</returns>
///
METHOD WACCustomer:setupPrototype()
  ::_Prototype              := DataObject():new()

  // Customer ID and basic info
  ::_Prototype:cust_id      := ""   // C,8
  ::_Prototype:firstname    := ""   // C,50
  ::_Prototype:lastname     := ""   // C,50
  ::_Prototype:email        := ""   // C,100
  ::_Prototype:phone        := ""   // C,20

  // Address information
  ::_Prototype:street       := ""   // C,100
  ::_Prototype:city         := ""   // C,50
  ::_Prototype:state        := ""   // C,50
  ::_Prototype:zipcode      := ""   // C,10
  ::_Prototype:country      := ""   // C,50

  // Additional fields
  ::_Prototype:active       := .F.          // L,1
  ::_Prototype:created      := CToD("")     // D,8
  ::_Prototype:modified     := CToD("")     // D,8
  ::_Prototype:notes        := ""           // M,10
RETURN SELF


/// <summary>
/// Writes a DataObject back to the current workarea record.
/// Sets modified to today's date on every write.
/// Sets created to today's date only when the field is empty (new record).
/// </summary>
///
/// <param name="oE">DataObject containing the field values to write</param>
/// <returns>Object: the DataObject after timestamp fields have been updated</returns>
///
METHOD WACCustomer:toWorkarea(oE)
  // Set modified (acts as the "updated" timestamp) to today's date
  oE:modified := Date()

  // Set created only when it has not been set yet (new record)
  IF Empty(oE:created)
    oE:created := oE:modified
  ENDIF

  GATHER NAME oE
RETURN oE


/// <summary>
/// Reads the current workarea record into a DataObject.
/// All character fields are trimmed before returning.
/// The notes memo field is returned as-is without trimming.
/// </summary>
///
/// <returns>Object: DataObject populated from the current workarea record</returns>
///
METHOD WACCustomer:fromWorkarea()
  LOCAL oE := NIL

  SCATTER NAME oE

  // Trim character fields
  oE:cust_id   := AllTrim(oE:cust_id)
  oE:firstname := AllTrim(oE:firstname)
  oE:lastname  := AllTrim(oE:lastname)
  oE:email     := AllTrim(oE:email)
  oE:phone     := AllTrim(oE:phone)
  oE:street    := AllTrim(oE:street)
  oE:city      := AllTrim(oE:city)
  oE:state     := AllTrim(oE:state)
  oE:zipcode   := AllTrim(oE:zipcode)
  oE:country   := AllTrim(oE:country)
  // notes is a Memo field - returned as-is (no trim)
RETURN oE
