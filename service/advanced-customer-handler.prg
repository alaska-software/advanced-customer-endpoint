//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Example: RestHandler using interceptors
/// </summary>
///
/// <remarks>
/// This example demonstrates how to use interceptors with a RestHandler.
/// Shows registration of multiple interceptors with method filtering.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "appevent.ch"
#include "common.ch"

CLASS CustomerHandler FROM RestHandler
  EXPORTED:
  CLASS METHOD onRegister( oEndpoint )
  METHOD getAll()
  METHOD getById( nId )
  METHOD getByName( cName )
  METHOD saveById( nId, oCustomer )
  METHOD deleteById( nId )
ENDCLASS


/// <summary>
/// Register routes, types, and interceptors
/// </summary>
///
CLASS METHOD CustomerHandler:onRegister( oEndpoint )
  // Register interceptors in order of execution
  // Note: Interceptors execute in registration order

  // 1. Logging for all methods - executes first
  ::addInterceptor( "LoggingInterceptor", NIL )

  // 2. Authentication for all methods - executes second
  ::addInterceptor( "AuthInterceptor", NIL )

  // 3. Caching only for read operations - executes third
  ::addInterceptor( "CacheInterceptor", {"getAll", "getById", "getByName"} )

  // Register parameter types
  ::addType( "id", "N" )
  ::addType( "name", "C" )
  ::addType( "customer", "O" )

  // Register routes
  ::map( "GET", "/customer/all", "getAll", "envelope" )
  ::map( "GET", "/customer/::id", "getById", "envelope" )
  ::map( "GET", "/customer/search/::name", "getByName", "envelope" )
  ::map( "PUT", "/customer/::id", "saveById", "envelope" )
  ::map( "DELETE", "/customer/::id", "deleteById", "envelope" )

  UNUSED(oEndpoint)
RETURN


/// <summary>
/// Retrieve all customers
/// </summary>
///
METHOD CustomerHandler:getAll()
  LOCAL aCustomers

  // Business logic
  aCustomers := CustomerDataMgr():getAll()

RETURN aCustomers


/// <summary>
/// Retrieve customer by ID
/// </summary>
///
METHOD CustomerHandler:getById( nId )
  LOCAL oCustomer

  // Business logic
  oCustomer := CustomerDataMgr():getById( nId )

  IF IsNull(oCustomer)
    ::setError( 404, "Customer not found" )
    RETURN NIL
  ENDIF

RETURN oCustomer


/// <summary>
/// Search customers by name
/// </summary>
///
METHOD CustomerHandler:getByName( cName )
  LOCAL aCustomers

  // Business logic
  aCustomers := CustomerDataMgr():getByName( cName )

  IF Empty(aCustomers)
    ::setError( 404, "No customers found matching: " + cName )
    RETURN {}
  ENDIF

RETURN aCustomers


/// <summary>
/// Save or update customer by ID
/// </summary>
///
METHOD CustomerHandler:saveById( nId, oCustomer )
  LOCAL lSuccess

  // Business logic
  IF nId==0
    lSuccess := CustomerDataMgr():add( oCustomer )
  ELSE
    lSuccess := CustomerDataMgr():update( nId, oCustomer )
  ENDIF

  IF !lSuccess
    ::setError( 500, "Failed to save customer" )
    RETURN NIL
  ENDIF

RETURN oCustomer


/// <summary>
/// Delete customer by ID
/// </summary>
///
METHOD CustomerHandler:deleteById( nId )
  LOCAL lSuccess

  // Business logic
  lSuccess := CustomerDataMgr():delete( nId )

  IF !lSuccess
    ::setError( 404, "Customer not found" )
    RETURN .F.
  ENDIF

RETURN .T.
