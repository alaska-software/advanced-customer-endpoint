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
  METHOD getById( cId )
  METHOD getByName( cName )
  METHOD updateById( cId, oCustomer )
  METHOD create()
  METHOD deleteById( cId )
ENDCLASS


/// <summary>
/// Register routes, types, and interceptors
/// </summary>
///
/// <param name="oEndpoint">REST endpoint instance (unused directly; registration uses class methods)</param>
///
CLASS METHOD CustomerHandler:onRegister( oEndpoint )

  // Register parameter types
  ::addType( "id", "C" )
  ::addType( "name", "C" )
  ::addType( "customer", "O" )

  // Register routes
  ::map( "GET", "/customer/all", "getAll", "envelope" )
  ::map( "GET", "/customer/::id", "getById", "envelope" )
  ::map( "GET", "/customer/search/::name", "getByName", "envelope" )
  ::map( "POST", "/customer", "create", "envelope" )
  ::map( "PUT", "/customer/::id", "updateById", "envelope" )
  ::map( "DELETE", "/customer/::id", "deleteById", "envelope" )

  // Register interceptors in order of execution
  // Note: Interceptors execute in registration order

  // 1. Logging for all methods - executes first
  ::addInterceptor( "LoggingInterceptor", NIL )

  // 2. Authentication for all methods - executes second
  ::addInterceptor( "AuthInterceptor", NIL )

  // 3. Caching only for read operations - executes third
  ::addInterceptor( "CacheInterceptor", {"getAll", "getById", "getByName"} )

  UNUSED(oEndpoint)
RETURN


/// <summary>
/// Retrieve all customers
/// </summary>
///
/// <returns>Array: all customer records, or NIL on data access failure</returns>
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
/// <param name="cId">Customer ID to retrieve</param>
/// <returns>Object: matching customer record, or NIL with HTTP 404 set if not found</returns>
///
METHOD CustomerHandler:getById( cId )
  LOCAL oCustomer

  // Business logic
  oCustomer := CustomerDataMgr():getById( cId )

  IF IsNull(oCustomer)
    ::setError( 404, "Customer not found" )
    RETURN NIL
  ENDIF

RETURN oCustomer


/// <summary>
/// Search customers by name
/// </summary>
///
/// <param name="cName">Name fragment to search for</param>
/// <returns>Array: matching customer records, or empty array with HTTP 404 set if none found</returns>
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
/// Update customer by ID
/// </summary>
///
/// <param name="cId">Customer ID of the record to update</param>
/// <param name="oCustomer">DataObject with updated field values</param>
/// <returns>Object: updated customer record, or NIL with HTTP 500 set on failure</returns>
///
METHOD CustomerHandler:updateById( cId, oCustomer )
  LOCAL lSuccess

  // Business logic
  lSuccess := CustomerDataMgr():update( cId, @oCustomer )

  IF !lSuccess
    ::setError( 500, "Failed to save customer" )
    RETURN NIL
  ENDIF

RETURN oCustomer


/// <summary>
/// Add new customer
/// </summary>
///
/// <param name="oCustomer">DataObject with new customer field values</param>
/// <returns>Object: created customer record, or NIL with HTTP 500 set on failure</returns>
///
METHOD CustomerHandler:create( oCustomer )
  LOCAL lSuccess

  lSuccess := CustomerDataMgr():add( @oCustomer )

  IF !lSuccess
    ::setError( 500, "Failed to create customer" )
    RETURN NIL
  ENDIF

RETURN oCustomer


/// <summary>
/// Delete customer by ID
/// </summary>
///
/// <param name="cId">Customer ID of the record to delete</param>
/// <returns>Logical: .T. on success, .F. with HTTP 404 set if not found</returns>
///
METHOD CustomerHandler:deleteById( cId )
  LOCAL lSuccess

  lSuccess := CustomerDataMgr():delete( cId )

  IF !lSuccess
    ::setError( 404, "Customer not found" )
    RETURN .F.
  ENDIF

RETURN .T.
