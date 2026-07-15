//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// Example: Caching interceptor for REST handlers
/// </summary>
///
/// <remarks>
/// This interceptor demonstrates how to implement caching as a
/// cross-cutting concern. It caches method results based on method
/// name and parameters, and returns cached results on subsequent calls.
/// </remarks>
///
/// <copyright>
/// Alaska Software Inc. (c) 2026. All rights reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "appevent.ch"
#include "common.ch"

CLASS CacheInterceptor FROM RestInterceptor
  PROTECTED:
  CLASS VAR Cache

  METHOD buildCacheKey( cMethod, aParams )

  EXPORTED:
  CLASS METHOD initClass()
  METHOD before( oHandler, cMethod, aParams )
  METHOD after( oHandler, cMethod, xResult )
ENDCLASS


/// <summary>
/// Initialize class-level cache storage
/// </summary>
///
/// <returns>Self: class reference after initialization</returns>
///
CLASS METHOD CacheInterceptor:initClass()
  ::RestInterceptor:initClass()
  ::Cache := DataObject():new()
RETURN


/// <summary>
/// Builds a cache key from method name and serialized parameters
/// </summary>
///
/// <param name="cMethod">Name of the handler method</param>
/// <param name="aParams">Array of method parameters used to differentiate cache entries</param>
/// <returns>String: cache key derived from method name and serialized parameters</returns>
///
METHOD CacheInterceptor:buildCacheKey( cMethod, aParams )
  LOCAL cKey

  // Create unique key from method and parameters
  cKey := cMethod

  IF Len(aParams) > 0
    cKey := cKey + ":" + Var2Json(aParams)
  ENDIF

RETURN cKey


/// <summary>
/// Checks cache before method execution. Votes to ignore (short-circuit) on a cache hit,
/// or commits execution to proceed to the actual method on a miss.
/// </summary>
///
/// <param name="oHandler">RestHandler instance (unused)</param>
/// <param name="cMethod">Name of the handler method to look up in the cache</param>
/// <param name="aParams">Array of method parameters used to build the cache key</param>
/// <returns>Self: instance reference</returns>
///
METHOD CacheInterceptor:before( oHandler, cMethod, aParams )
  LOCAL cCacheKey, xCached

  UNUSED(oHandler)

  // Build cache key
  cCacheKey := ::buildCacheKey( cMethod, aParams )

  // Check if result is cached
  IF IsMemberVar(::Cache, cCacheKey )
    xCached := ::Cache:getNoIVar( cCacheKey )

    XppRtFileLogger():warning( "Cache HIT for " + cMethod )

    // Short-circuit with cached result
    ::voteIgnore( xCached )
    RETURN SELF
  ENDIF

  XppRtFileLogger():warning( "Cache MISS for " + cMethod )

  // Not in cache - continue to method execution
  ::voteCommit()

RETURN SELF


/// <summary>
/// Stores the method result in the cache after execution and passes the result through.
/// </summary>
///
/// <param name="oHandler">RestHandler instance (unused)</param>
/// <param name="cMethod">Name of the handler method whose result is being cached</param>
/// <param name="xResult">The method result value to store and pass through</param>
/// <returns>Value: xResult passed through unchanged</returns>
///
METHOD CacheInterceptor:after( oHandler, cMethod, xResult )
  LOCAL cCacheKey, aParams

  UNUSED(oHandler)

  // Note: In a full implementation, we'd need to get parameters
  // For this example, we'll cache based on method name only
  aParams := {}  // Simplified

  cCacheKey := ::buildCacheKey( cMethod, aParams )

  // Store result in cache
  ::Cache:setNoIvar( cCacheKey, xResult )

  XppRtFileLogger():warning( "Cached result for " + cMethod )

RETURN xResult  // Pass through
