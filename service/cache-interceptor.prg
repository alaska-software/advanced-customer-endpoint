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
/// Cache entries are stored in a class-level DataObject keyed by method
/// name and serialized parameters.
///
/// Cache invalidation: write operations listed in before() wipe the
/// entire cache so stale reads cannot follow a mutation.
///
/// Cache bypass: callers may send the HTTP header "Cache-Control: no-cache"
/// to force a live execution and skip both the cache lookup and storage.
/// This is used by unit tests to prevent cached responses from interfering
/// with test assertions.
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
      VAR CacheKey

      METHOD buildCacheKey( cMethod, aParams )

   EXPORTED:
      CLASS METHOD initClass()
      CLASS METHOD reset()
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
   ::reset()
RETURN


/// <summary>
/// Clears the entire class-level cache store
/// </summary>
///
/// <remarks>
/// Called at class initialization and whenever a mutation is detected
/// in before(). Replaces the cache DataObject with a fresh instance,
/// which effectively invalidates all previously cached entries.
/// </remarks>
///
/// <returns>NIL</returns>
///
CLASS METHOD CacheInterceptor:reset()
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
/// <remarks>
/// Execution order:
/// 1. Build and store the cache key from method name and parameters.
/// 2. If the request carries "Cache-Control: no-cache", bypass the cache
///    entirely and vote commit so the method always executes. The result
///    will not be stored by after() either because ::CacheKey is still set
///    but the caller expects a fresh response.
/// 3. On a cache hit with a non-null value, return the stored result
///    immediately via voteIgnore, skipping the actual method.
/// 4. On a miss, vote commit to allow normal method execution.
/// </remarks>
///
/// <param name="oHandler">RestHandler instance used to read HTTP request headers</param>
/// <param name="cMethod">Name of the handler method to look up in the cache</param>
/// <param name="aParams">Array of method parameters used to build the cache key</param>
/// <returns>Self: instance reference</returns>
///
METHOD CacheInterceptor:before( oHandler, cMethod, aParams )
   LOCAL xCached
   LOCAL cNoCache

   // Build cache key and store it for use in after()
   ::CacheKey := ::buildCacheKey( cMethod, aParams )

   // Respect cache control
   cNoCache := oHandler:httpRequest:getHeader("Cache-Control")
   IF ValType(cNoCache)=="C" .AND. cNoCache=="no-cache"
      XppFileLogger():warning( "No-Cache for " + cMethod )
      ::voteCommit()
      RETURN SELF
   ENDIF

   // Check if result is cached
   IF IsMemberVar(::Cache, ::CacheKey )
      xCached := ::Cache:getNoIVar( ::CacheKey )

      IF !IsNull(xCached)
        XppFileLogger():warning( "Cache HIT for " + cMethod )

        // Short-circuit with cached result
        ::voteIgnore( xCached )
        RETURN SELF
      ENDIF
   ENDIF

   XppFileLogger():warning( "Cache MISS for " + cMethod )

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
   UNUSED(oHandler)
   UNUSED(cMethod)

   // Store result in cache using the key built in before()
   ::Cache:setNoIvar( ::CacheKey, xResult )

   XppFileLogger():warning( "Cached result for " + cMethod )

RETURN xResult  // Pass through
