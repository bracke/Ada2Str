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

-- $Author$
-- $Date$
-- $Revision$

with RASCAL.OS;
with RASCAL.Utility;          use RASCAL.Utility;

with Kernel;                  use Kernel;
with Interfaces.C;            use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;
with Reporter;

package body RASCAL.WimpSlot is

   -- Exceptions

   Error_Reading_Page_Size : Exception;

   -- Constants

   Wimp_SlotSize        : constant := 16#400EC#;
   OS_ReadMemMapInfo    : constant := 16#51#;

   -- Methods

   function Get_WimpSlot_Size return natural is

      Register             : aliased Kernel.swi_regs;
      Error                : Kernel.oserror_access;
   begin
      Register.R (0) := -1;
      Register.R (1) := -1;
      Error := Kernel.SWI (Wimp_SlotSize, Register'Access, Register'Access);
   
      if Error /= null then
         pragma Debug(Reporter.Report("WimpSlot- Read wimpslot size:  " &
                                         To_Ada(Error.errmess)));
         OS.Raise_Error(Error);
      end if;
      return natural (Register.R (0));
   end Get_WimpSlot_Size;

   --

   function Get_NextSlot_Size return natural is

      Register             : aliased Kernel.swi_regs;
      Error                : Kernel.oserror_access;
   begin
      Register.R (0) := -1;
      Register.R (1) := -1;
      Error := Kernel.SWI (Wimp_SlotSize, Register'Access, Register'Access);
   
      if Error /= null then
         pragma Debug(Reporter.Report("WimpSlot- Read nextslot size:  " &
                                         To_Ada(Error.errmess)));
         OS.Raise_Error(Error);
      end if;
      return natural (Register.R (1));
   end Get_NextSlot_Size;

   --

   function Get_Page_Size return natural is

      Register             : aliased Kernel.swi_regs;
      Error                : Kernel.oserror_access;
   begin
      Error := Kernel.SWI (OS_ReadMemMapInfo, Register'Access,Register'Access);
   
      if Error /= null then
         pragma Debug(Reporter.Report("WimpSlot - Get_Page_Size:  " &
                                          To_Ada(Error.errmess)));
         OS.Raise_Error(Error);
         raise Error_Reading_Page_Size;
         
      else
         -- Page size in bytes
         return natural(Register.R (0));
      end if;

   end Get_Page_Size;

   --

   function Page_Align (Nr : integer) return integer is

      Absolute_Nr          : natural := abs (Nr);
      Page_Size            : natural;
      Pages                : natural;
      Aligned              : natural;
   begin
      if Nr = 0 then
         return 0;
      end if;

      Page_Size := Get_Page_Size;
      Pages := Absolute_Nr / Page_Size;
      Aligned := Pages * Page_Size;

      if Aligned < Absolute_Nr then
         Pages := Pages + 1;
         Aligned := Pages * Page_Size;
      end if;

      if Nr < 0 then
         return -1 * integer(Aligned);
      else
         return integer(Aligned);
      end if;
   end Page_Align;

   --

   procedure Resize_WimpSlot(Size_Change : in integer) is
   
      Register             : aliased Kernel.swi_regs;
      Error                : Kernel.oserror_access;
      Current_Size         : natural  := Get_WimpSlot_Size;
      Page_Size            : natural;
      Pages                : natural;
      Change               : positive := abs (Size_Change);
      Real_Change          : integer;
   begin
      if Size_Change /= 0 then
         Page_Size := Get_Page_Size;
         Pages := Change / Page_Size;

         if Size_Change > 0 then
            Pages       := Pages + 1;
            Real_Change := Pages * Page_Size;
         else
            Pages       := Pages - 1;
            Real_Change := - (Pages * Page_Size);
         end if;
         Register.R (0) := int (Current_Size + Real_Change);
         Register.R (1) := -1;
         Error := Kernel.SWI (Wimp_SlotSize, Register'Access,Register'Access);
         
         if Error /= null then
            pragma Debug(Reporter.Report("WimpSlot - Resize_WimpSlot:  " &
                                                 To_Ada(Error.errmess)));
            OS.Raise_Error(Error);
         end if;

      end if;

   end Resize_WimpSlot;

   --

   procedure Set_WimpSlot(New_Size : in natural) is
   
      Register             : aliased Kernel.swi_regs;
      Error                : Kernel.oserror_access;
      Real_Size            : integer;
   begin
      Real_Size := Page_Align(New_Size);
      Register.R (0) := int (Real_Size);
      Register.R (1) := -1;
      Error := Kernel.SWI (Wimp_SlotSize, Register'Access,Register'Access);
      
      if Error /= null then
         pragma Debug(Reporter.Report("WimpSlot - Set_WimpSlot:  " &
                                              To_Ada(Error.errmess)));
         OS.Raise_Error(Error);
      end if;
   end Set_WimpSlot;

   --

   procedure Set_NextSlot (Size : in natural) is

      Register             : aliased Kernel.swi_regs;
      Error                : Kernel.oserror_access;
      Real_Size            : natural;
   begin
      Real_Size := Page_Align(Size);
      Register.R (0) := -1;
      Register.R (1) := int (Real_Size);
      Error := Kernel.SWI (Wimp_SlotSize, Register'Access,Register'Access);

      if Error /= null then
         pragma Debug(Reporter.Report("WimpSlot - Set_NextSlot:  " &                                                 To_Ada(Error.errmess)));
         OS.Raise_Error(Error);
      end if;
   end Set_NextSlot;

   --

end RASCAL.WimpSlot;
