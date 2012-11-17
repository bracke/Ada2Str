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
with RASCAL.Memory;           use RASCAL.Memory;

with Interfaces.C;            use Interfaces.C;
with System.Storage_Elements; use System.Storage_Elements;
with Kernel;                  use Kernel;
with Ada.Strings.Maps;        use Ada.Strings.Maps;
with Ada.Strings;             use Ada.Strings;
with Reporter;

package body RASCAL.FS is

   OS_FSControl : constant := 16#29#;

   --

   function Get_FSName (FS_Number : in integer) return string is

      Error          : oserror_access;
      Register       : aliased Kernel.swi_regs;
      Buffer         : string(1..255);
   begin
      Register.R(0) := 33;
      Register.R(1) := int(FS_Number);
      Register.R(2) := Adr_To_Int(Buffer'Address);
      Register.R(3) := 255;
      Error := Kernel.swi(OS_FSControl,register'Access,register'Access);

      if Error /= null then
         pragma Debug(Reporter.Report("FS.Get_FSName: " & To_Ada(Error.ErrMess)));
         OS.Raise_Error(Error);
      end if;

      return MemoryToString(Buffer'Address);
      
   end Get_FSName;

   --

   function Get_All_FS return FS_List_Pointer is

      Error          : oserror_access;
      Register       : aliased Kernel.swi_regs;
      Module_Name    : String := "FileCore%Base" & Character'Val(0);
      Module         : Unbounded_String;

      OS_Module             : constant := 16#1E#;
      FileCore_Drives       : constant := 16#40542#;
      FileCore_DescribeDisc : constant := 16#40545#;

      Module_Nr      : integer;
      Instantiations : integer;
      PFix           : integer;
      Floppy_Drives  : integer;
      Hard_Drives    : integer;

      Disc_Names     : Unbounded_String;
      Systemname     : Unbounded_String;
      Discname       : Unbounded_String;
      Msg            : Unbounded_String;

      ll             : integer;
      Block          : String(1..255);
      Word           : integer;
      Loop_Counter   : integer := 0;

      function Write_Array (Disc_Names : in Unbounded_String) return FS_List_Pointer is

         Drives : integer := Count(Disc_Names,",");
         FS_List: FS_List_Pointer := FS_List_Pointer'(new FS_List_Type(1..Drives));
         Source : Unbounded_String := Disc_Names & ",";
         From : integer;
         To : integer;
      begin
         for i in FS_List'Range loop
            Find_Token(Source,To_Set(','),Outside,From,To);
            FS_List.all(i) := U(Slice(Source,From,To));
            Delete(Source,From,To);
         end loop;
         return FS_List;
      end Write_Array;
   begin
      loop
         Register.R(0) := 18;
         Register.R(1) := Adr_To_Int(Module_Name'address);
         error := Kernel.swi(OS_Module,register'Access,register'Access);
         
         if error /= null then
            Loop_Counter := Loop_Counter + 1;
         else
            exit;
         end if;
      end loop;
      Module_Nr      := integer(Register.R(1));
      Instantiations := integer(Register.R(2));
      
      for l in 0..Instantiations-1 loop
         ll := 0;
         Register.R(0) := 12;
         Register.R(1) := int(Module_Nr);
         Register.R(2) := int(l);
         Error := Kernel.swi(OS_Module,register'Access,register'Access);

         --exit when error /= null;
         if Error /= null then
            pragma Debug(Reporter.Report("FS.OS_Module 12 returned error: " & To_Ada(Error.ErrMess)));
            OS.Raise_Error(Error);
            -- `No more modules' or `No more incarnations of that module'.
         end if;
         Word := GetWord(Int_To_Adr(Register.R(4)));
         PFix  := integer(Register.R(5));
         Register.R(0) := 0;
         Register.R(1) := 0;
         Register.R(2) := 0;
         Register.R(3) := 0;
         Register.R(4) := 0;
         Register.R(5) := 0;
         Register.R(6) := 0;
         Register.R(7) := 0;
         Register.R(8) := int(Word);
         error := Kernel.swi(FileCore_Drives,register'Access,register'Access);

         Floppy_Drives := integer(Register.R(1));
         Hard_Drives   := integer(Register.R(2));

         if Hard_Drives > 0 then
            ll := 3;
            for lll in 1..Hard_Drives loop
                loop
                  ll := ll +1;
                  Module := U(":" & intstr(ll) & Character'Val(0));
                  Register.R(0) := Adr_To_Int(To_String(Module)'Address);
                  Register.R(1) := Adr_To_Int(Block'Address);
                  Register.R(2) := 0;
                  Register.R(3) := 0;
                  Register.R(4) := 0;
                  Register.R(5) := 0;
                  Register.R(6) := 0;
                  Register.R(7) := 0;
                  Register.R(8) := int(Word);
                  Error := Kernel.swi(FileCore_DescribeDisc,register'Access,register'Access);

                  exit when ll=64;
                  exit when Error = null;
                end loop;
                if Error = null then
                   Systemname := U(MemoryToString(Int_To_Adr(int(PFix))));
                   Discname   := U(MemoryToString(Block'Address,22,10));
                   Trim(Systemname,Both);
                   Trim(Discname,Both);
                   if Length(Discname) = 0 then
                      Discname := U(intstr(ll));
                   end if;
                   Msg := Systemname & U("::") & Discname & U(".$");
                   Disc_Names := Disc_Names & U(",") & Msg;
                end if;

            end loop;

         end if;
         -- Floppy drives
         if Floppy_Drives > 0 then
            ll := ll - 1;
            for lll in 1..Floppy_Drives loop
                ll := ll + 1;
                Systemname := U(MemoryToString(Int_To_Adr(int(PFix))));
                Msg := Systemname & U("::") & U(intstr(ll)) & U(".$");
                Disc_Names := Disc_Names & U(",") & Msg;
            end loop;
         end if;
      end loop;
      
      if error /= null then
         pragma Debug(Reporter.Report("FS: Error: " & To_Ada(Error.ErrMess)));
         OS.Raise_Error(Error);
      end if;
      return Write_Array(Disc_Names);
   end Get_All_FS;

   --

   function FreeSpace (discname     : in String) return Integer is
   
      discname_0 : String := discname & ASCII.NUL;
      Error      : oserror_access;
      register   : aliased Kernel.swi_regs;
   begin
     Register.R(0) := 55;
     Register.R(1) := int(To_Integer(discname_0'Address));
     Error := Kernel.SWI(OS_FSControl,Register'Access,Register'Access);
     if Error /= NULL then
       Register.R(0) := 49;
       Register.R(1) := Int(To_Integer(discname_0'Address));
       Error := Kernel.swi(OS_FSControl,Register'Access,Register'Access);
       if Error /= NULL then
         return 0;
       else
         return Integer(Register.r(1));
       end if;
     else
       return Integer(Register.r(2));
     end if;
   end FreeSpace;

   --

   function EnoughSpace (DiscName     : in String;
                         Needed_Bytes : in Integer) return Boolean is
   begin
     if FreeSpace(DiscName) < Needed_Bytes then
       return false;
     else
       return true;
     end if;
   end EnoughSpace;

   --

   procedure Set_CSD (Path : in String) is
   
      Path_0    : String := Path & ASCII.NUL;
      Error     : oserror_access;
      Register  : aliased Kernel.swi_regs;   
   begin
      Register.R(0) := 0;
      Register.R(1) := Adr_To_Int(Path_0'Address);
      Error := Kernel.SWI(OS_FSControl,Register'Access,Register'Access);

      if Error /= null then
         pragma Debug(Reporter.Report("FS.Set_CSD: " & To_Ada(Error.errmess)));
         OS.Raise_Error(Error);
      end if;
   end Set_CSD;

   --

end RASCAL.FS;
