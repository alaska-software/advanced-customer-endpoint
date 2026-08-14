//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Customer address DBF table schema and creation
/// </summary>
///
/// <remarks>
/// Defines the structure for a customer address database table
/// including customer information and address details
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "common.ch"
#include "dmlb.ch"

/// <summary>
/// Creates a customer address DBF table with predefined structure
/// </summary>
///
/// <param name="cPath">Path where the customer.dbf file will be created (defaults to current directory)</param>
/// <returns>Logical: .T. if table created successfully, .F. on failure</returns>
///
FUNCTION CreateCustomerTable( cPath )
  LOCAL aStruct := {}
  LOCAL cDBF := "customer"
  LOCAL lSuccess := .F.
  LOCAL oE

  DEFAULT cPath TO ".\"

  aStruct := GetCustomerStructure()

  // Create the DBF table with DBFCDX driver
  BEGIN TRY
     DbCreate( cPath + cDBF, aStruct, "FOXCDX" )
     lSuccess := .T.
  RECOVER USING oE
     lSuccess := .F.
  END

RETURN lSuccess

/// <summary>
/// Returns the customer table structure definition
/// </summary>
///
/// <returns>Array: Table structure definition with field specifications</returns>
///
FUNCTION GetCustomerStructure()
  LOCAL aStruct := {}

  // Customer ID and basic info
  AAdd( aStruct, { "cust_id",    "C",  8, 0 } )  // Customer ID (unique)
  AAdd( aStruct, { "firstname",  "C", 50, 0 } )  // First name
  AAdd( aStruct, { "lastname",   "C", 50, 0 } )  // Last name
  AAdd( aStruct, { "email",      "C", 100, 0 } ) // Email address
  AAdd( aStruct, { "phone",      "C", 20, 0 } )  // Phone number

  // Address information
  AAdd( aStruct, { "street",     "C", 100, 0 } ) // Street address
  AAdd( aStruct, { "city",       "C", 50, 0 } )  // City
  AAdd( aStruct, { "state",      "C", 50, 0 } )  // State/Province
  AAdd( aStruct, { "zipcode",    "C", 10, 0 } )  // ZIP/Postal code
  AAdd( aStruct, { "country",    "C", 50, 0 } )  // Country

  // Additional fields
  AAdd( aStruct, { "active",     "L", 1, 0 } )   // Active status
  AAdd( aStruct, { "created",    "D", 8, 0 } )   // Date created
  AAdd( aStruct, { "modified",   "D", 8, 0 } )   // Date modified
  AAdd( aStruct, { "notes",      "M", 10, 0 } )  // Memo field for notes

RETURN aStruct


/// <summary>
/// Creates indexes for the currently open customer table
/// </summary>
///
/// <returns>Logical: .T. if indexes created successfully, .F. on failure or if no table is open</returns>
///
FUNCTION CreateCustomerIndexes()
  LOCAL lSuccess := .F.
  FIELD cust_id, lastname, firstname, email, city, active

  IF !Used()
    RETURN .F.
  ENDIF

  BEGIN SEQUENCE
    // Primary key index on customer ID (unique identifier)
    INDEX ON cust_id TAG cust_id TO customer FOR !Deleted()

    // Secondary indexes for searching and filtering
    INDEX ON Upper( lastname - firstname ) TAG name TO customer FOR !Deleted()  // Full name search
    INDEX ON Upper( email ) TAG email TO customer FOR !Deleted()                 // Email lookup
    INDEX ON Upper( city ) TAG city TO customer FOR !Deleted()                   // City-based queries
    INDEX ON active TAG active TO customer FOR !Deleted()                        // Active status filter

    // Set default ordering to customer ID
    SET ORDER TO TAG cust_id

    lSuccess := .T.
  RECOVER
    lSuccess := .F.
  END SEQUENCE

RETURN lSuccess
