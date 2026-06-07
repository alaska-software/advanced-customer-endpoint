//////////////////////////////////////////////////////////////////////
///
/// <summary>
/// This is a standard console mode exe.
/// </summary>
///
///
/// <remarks>
/// </remarks>
///
///
/// <copyright>
/// Your-Company. All Rights Reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "Common.ch"

/* This is our main procedure
 */
PROCEDURE Main

  /* we use the ansi charset by default */
  SET CHARSET TO ANSI

  CreateCustomerTable( "./" )
  CreateCustomerIndexes()

RETURN