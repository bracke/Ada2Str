--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2004, RISC OS Ada Library (RASCAL) developers.               --
--                                                                            --
-- This library is free software; you can redistribute it and/or              --
-- modify it under the terms of the GNU Lesser General Public                 --
-- License as published by the Free Software Foundation; either               --
-- version 2.1 of the License, or (at your option) any later version.         --
--                                                                            --
-- This library is distributed in the hope that it will be useful,            --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of             --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU           --
-- Lesser General Public License for more details.                            --
--                                                                            --
-- You should have received a copy of the GNU Lesser General Public           --
-- License along with this library; if not, write to the Free Software        --
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA    --
--                                                                            --
--------------------------------------------------------------------------------

-- @brief Wimpslot related methods.
-- $Author$
-- $Date$
-- $Revision$

package RASCAL.WimpSlot is

   --
   -- Find the size of the tasks wimpslot.
   --
   function Get_WimpSlot_Size return natural;

   --
   -- Find the size of the next slot - the amount of memory
   -- allocated to the next application.
   --
   function Get_NextSlot_Size return natural;

   --
   -- Find the page size.
   --
   function Get_Page_Size return natural;

   --
   -- Page align Nr.
   --
   function Page_Align (Nr : integer) return integer;

   --
   -- Change the size of the tasks wimpslot.
   --
   procedure Resize_WimpSlot(Size_Change : in integer);

   --
   -- Set the size of the tasks wimpslot.
   --
   procedure Set_WimpSlot(New_Size : in natural);

   --
   -- Set the size of the next slot - the amount of memory
   -- allocated to the next application.
   --
   procedure Set_NextSlot (Size : in natural);

end RASCAL.WimpSlot;
