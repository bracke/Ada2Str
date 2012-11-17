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

-- @brief Filing system related subprograms.
-- $Author$
-- $Date$
-- $Revision$

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package RASCAL.FS is

   type FS_List_Type is
      array (integer range <>) of Unbounded_String;

   type FS_List_Pointer is access FS_List_Type;

   --
   -- Converts FS number to name. If the the FS number is unknown a null string is returned.
   --
   function Get_FSName (FS_Number : in integer) return string;

   --
   -- Returns a list of available filing systems.
   --
   function Get_All_FS return FS_List_Pointer;

   --
   -- Returns free space (in bytes) of discname
   --also works on filenames, if the file is open
   --
   function FreeSpace (discname : in String) return Integer;

   --
   -- Returns true if there is (more than) needed_bytes free on discname.
   --also works on filenames, if the file is open!
   --
   function EnoughSpace (discname     : in String;
                         needed_bytes : in Integer) return Boolean ;

   --
   -- Sets the current directory to 'Path'.
   --
   procedure Set_CSD (Path : in String);
      
end RASCAL.FS;
