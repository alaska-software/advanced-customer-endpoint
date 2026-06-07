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
CLASS METHOD CacheInterceptor:initClass()
  ::RestInterceptor:initClass()
  ::Cache := DataObject():new()
RETURN


/// <summary>
/// Builds a cache key from method name and parameters
/// </summary>
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
/// Checks cache before method execution
/// </summary>
///
METHOD CacheInterceptor:before( oHandler, cMethod, aParams )
  LOCAL cCacheKey, xCached

  UNUSED(oHandler)

  // Build cache key
  cCacheKey := ::buildCacheKey( cMethod, aParams )

  // Check if result is cached
  IF ::Cache:isDefined( cCacheKey )
    xCached := ::Cache:&cCacheKey

    XppRtFileLogger():debug( "Cache HIT for " + cMethod )

    // Short-circuit with cached result
    ::voteIgnore( xCached )
    RETURN SELF
  ENDIF

  XppRtFileLogger():debug( "Cache MISS for " + cMethod )

  // Not in cache - continue to method execution
  ::voteCommit()

RETURN SELF


/// <summary>
/// Stores result in cache after method execution
/// </summary>
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

  XppRtFileLogger():debug( "Cached result for " + cMethod )

RETURN xResult  // Pass through
