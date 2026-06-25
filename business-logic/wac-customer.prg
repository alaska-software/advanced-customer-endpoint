// WACCustomer.prg
// Workarea Container class for customer.dbf
// Auto-generated from customer table data model

CLASS WACCustomer FROM WAContainer
  PROTECTED:
  CLASS METHOD use()
  METHOD setupPrototype()
  EXPORTED:
  METHOD fromWorkarea()
  METHOD toWorkarea()
ENDCLASS

// Opens the customer table with its compound index file
CLASS METHOD WACCustomer:use()
  LOCAL cPath, oNode
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

  // Open customer.dbf with customer.cdx compound index
  USE (cPath+"customer.dbf") INDEX (cPath+"customer.cdx") NEW ALIAS customer
RETURN SELF

// Sets up the prototype DataObject with all customer fields and their empty default values
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

// Writes the DataObject back to the workarea
// Sets modified to current date before saving
// Sets created to current date only if it is empty (new record)
METHOD WACCustomer:toWorkarea(oE)
  // Set modified (acts as the "updated" timestamp) to today's date
  oE:modified := Date()

  // Set created only when it has not been set yet (new record)
  IF Empty(oE:created)
    oE:created := oE:modified
  ENDIF

  GATHER NAME oE
RETURN oE

// Reads the current workarea record into a DataObject
// Trims all character fields before returning
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

