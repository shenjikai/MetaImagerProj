/*****************************************************************************
*                                                                            *
*  OpenNI 1.0 Alpha                                                          *
*  Copyright (C) 2010 PrimeSense Ltd.                                        *
*                                                                            *
*  This file is part of OpenNI.                                              *
*                                                                            *
*  OpenNI is free software: you can redistribute it and/or modify            *
*  it under the terms of the GNU Lesser General Public License as published  *
*  by the Free Software Foundation, either version 3 of the License, or      *
*  (at your option) any later version.                                       *
*                                                                            *
*  OpenNI is distributed in the hope that it will be useful,                 *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of            *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the              *
*  GNU Lesser General Public License for more details.                       *
*                                                                            *
*  You should have received a copy of the GNU Lesser General Public License  *
*  along with OpenNI. If not, see <http://www.gnu.org/licenses/>.            *
*                                                                            *
*****************************************************************************/




//---------------------------------------------------------------------------
// Includes
//---------------------------------------------------------------------------
#include <XnOS.h>

//---------------------------------------------------------------------------
// Code
//---------------------------------------------------------------------------
XN_CORE_API XnStatus XnOSCreateMutex(XN_MUTEX_HANDLE* pMutexHandle)
{
	// no need for mutex, since no threads exists
	return (XN_STATUS_OK);
}

XN_CORE_API XnStatus XnOSCreateNamedMutex(XN_MUTEX_HANDLE* pMutexHandle, const XN_CHAR* cpMutexName)
{
	// no need for mutex, since no threads exists
	return (XN_STATUS_OK);
}

XN_CORE_API XnStatus XnOSCloseMutex(XN_MUTEX_HANDLE* pMutexHandle)
{
	// no need for mutex, since no threads exists
	return (XN_STATUS_OK);
}

XN_CORE_API XnStatus XnOSLockMutex(const XN_MUTEX_HANDLE MutexHandle, XN_UINT32 nMilliseconds)
{
	// no need for mutex, since no threads exists
	return (XN_STATUS_OK);
}

XN_CORE_API XnStatus XnOSUnLockMutex(const XN_MUTEX_HANDLE MutexHandle)
{
	// no need for mutex, since no threads exists
	return (XN_STATUS_OK);
}
