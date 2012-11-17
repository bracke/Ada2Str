with Ada.Text_IO;                   use Ada.Text_IO;
with Ada.Strings.Unbounded;         use Ada.Strings.Unbounded;
with System.Unsigned_Types;         use System.Unsigned_Types;
with Ada.Strings.Fixed;
with Ada.Command_Line;
with Ada.Exceptions;

with RASCAL.FS;
with RASCAL.FileExternal;           use RASCAL.FileExternal;
with RASCAL.Utility;                use RASCAL.Utility;
with RASCAL.Variable;
with RASCAL.Module;
with RASCAL.WimpSlot;
with RASCAL.Time;

procedure Ada2Str is

   --

   package FS           renames RASCAL.FS;
   package FileExternal renames RASCAL.FileExternal;
   package Utility      renames RASCAL.Utility;     
   package Variable     renames RASCAL.Variable;    
   package Module       renames RASCAL.Module;      
   package WimpSlot     renames RASCAL.WimpSlot;    
   package Time         renames RASCAL.Time;        
                                           
   --

   procedure Syntax is
   begin
      New_Line;
      Put_Line ("Ada2Str creates StrongHelp dokumentation");
      Put_Line ("for Ada source code.");
      New_Line;
      Put_Line ("Use : ada2str <doc name> <source dir> <target dir>");
   end Syntax;

   No_Files_In_Source_Dir : exception;
   No_Scrapdir            : exception;
   No_StrongHelp          : exception;
   Too_Few_Arguments      : exception;
   Source_Does_Not_Exist  : exception;
   Target_Does_Not_Exist  : exception;

begin

   if Ada.Command_Line.Argument_Count < 3 then
      raise Too_Few_Arguments;
   end if;

   declare
      Source     : String  := StripLeadingSpaces(StripTrailingSpaces(Ada.Command_Line.Argument(2)));
      Target     : String  := StripLeadingSpaces(StripTrailingSpaces(Ada.Command_Line.Argument(3)));
      Doc_Name   : String  := StripLeadingSpaces(StripTrailingSpaces(Ada.Command_Line.Argument(1)));
      ScrapDir   : String  := Variable.Get_Value("Wimp$ScrapDir");
      UnixFSsFix : String  := Variable.Get_Value("UnixFS$sfix");
      Append_String : Unbounded_String;
   begin
      if not FileExternal.Exists(Source) then
         raise Source_Does_Not_Exist;
      end if;
      
      if not FileExternal.Exists(Target) then
         raise Target_Does_Not_Exist;
      end if;
      
      -- Is there a scrapdir ?
      if Variable.Get_Value("Wimp$ScrapDir") = "" then
         raise No_Scrapdir;
      end if;
      
      -- Is StrongHelp known ?
      if ScrapDir'Length = 0 then
         raise No_StrongHelp;
      end if;
      
      if not Module.is_Module("StrongHelp") then
         Utility.Call_OS_CLI("Filer_Run <StrongHelp$Dir>.!Run");
      end if;

      if UnixFSsFix'Length = 0 then
          Append_String := U("xml:ads:StrHelp:cfg");
       else
          if Ada.Strings.Fixed.Count(UnixFSsFix,"xml") = 0 then
             Append_String := Append_String & (U(":xml"));
          end if;
          if Ada.Strings.Fixed.Count(UnixFSsFix,"ads") = 0 then
             Append_String := Append_String & (U(":ads"));
          end if;
          if Ada.Strings.Fixed.Count(UnixFSsFix,"sh") = 0 then
             Append_String := Append_String & (U(":sh"));
          end if;
          if Ada.Strings.Fixed.Count(UnixFSsFix,"cfg") = 0 then
             Append_String := Append_String & (U(":cfg"));
          end if;
       end if;
      
       if S(Append_String)'Length > 0 then
          Variable.Set_Value("UnixFS$sfix",UnixFSsFix & S(Append_String));
       end if;
      
      declare

         Dir_List : FileExternal.Directory_Type := FileExternal.Get_Directory_List(Source & ".ads");
      
         Files         : integer           := 0;
         Nr_Of_Columns : integer           := 0;
         Root          : File_Type;
         OType         : FileExternal.File_Object_Type;
      
      begin
      
         Files := Dir_List'Last;
      
         if Files = 0 then
            raise No_Files_In_Source_Dir;
         end if;

         case Files is
         when 1..80    => Nr_Of_Columns := 4;
         when 81..160  => Nr_Of_Columns := 5;
         when 161..240 => Nr_Of_Columns := 6;
         when 241..340 => Nr_Of_Columns := Files / 40;
         when others   => Nr_Of_Columns := Files / 60;
         end case;
      
         if FileExternal.Exists(Target & "." & Doc_Name) then
            FileExternal.Wipe (Target & "." & Doc_Name);
         end if;
      
         Utility.Call_OS_CLI("StrongCreate " & Target & "." & Doc_Name);
         FS.Set_CSD(Source);
      
         -- Creating StrongHelp pages
         for i in Dir_List'Range loop
            declare
            begin
               Put_line ("Creating StrongHelp file: " & S(Dir_list(i)));
               
               WimpSlot.Set_NextSlot(8*1024*1024);
               Utility.Call_OS_CLI("WimpTask <Ada2Str$Dir>.AdaDoc -S ads." &
                                   S(Dir_List(i)) & " > null:");
               
               FileExternal.Move(Source => Source & ".sh." & S(Dir_List(i)),
                                 Target => Target & "." & Doc_Name & "." & S(Dir_List(i)),
                                 Flags  => Copy_Option_Delete+Copy_Option_Force);
            exception
              when e: others => Put_Line (Ada.Exceptions.Exception_Information (e));
            end;
         end loop;
      
         Put_Line ("Creating root of StrongHelp manual.");
         
         -- Create index file
         Create (Root, Name => "<Wimp$ScrapDir>.Ada2Str");
         Put_Line(Root,Doc_Name);
         Put_Line(Root,"#Parent StrongHelp:!Root");
         Put_Line(Root,"#fh1:" & Doc_Name);
         Put_Line(Root,"#Line");
         Put_Line(Root,"#Table Columns " & intstr(Nr_Of_Columns));
      
         for i in Dir_List'Range loop
            OType := FileExternal.Get_Object_Type(Source & ".ads." & S(Dir_List(i)));
            if OType = File_Object then
               -- Update index file with link
               Put_Line(Root,"<" & S(Dir_List(i)) & "=>" & S(Dir_List(i)) & ">");
            end if;
         end loop;
      
         -- Write end of index files
         Put_Line(Root,"#EndTable");
         Put_Line(Root,"#Line");
         Put_Line(Root,"#Wrap Off");
         Put_Line(Root,"#Align Centre");
         Put_Line(Root,"Created by <Ada2Str=>#url http://www.arcsite.de/hp/bracke/>, " &
                       Time.Get_Date ("%ce%yr-%mn-%dy"));
         Close(Root);
         
         FileExternal.Move(Source => "<Wimp$ScrapDir>.Ada2Str",
                           Target => Target & "." & Doc_Name & ".!Root",
                           Flags  => Copy_Option_Delete+Copy_Option_Force);
      
         Put_Line("Done!");

      exception
         
         when Too_Few_Arguments =>
            Put_Line ("Error: Wrong number of arguments (<3)");
            Syntax;
         
         when Source_Does_Not_Exist =>
            Put_Line ("Error: Source does not exist");
            Syntax;
         
         when Target_Does_Not_Exist =>
            Put_Line ("Error: Target does not exist");
            Syntax;
         
         when No_StrongHelp =>
            Put_Line ("Error: StrongHelp could not be found. Please make sure");
            Put_Line ("it has been seen by the filer.");
         
         when No_Scrapdir =>
            Put_Line ("Error: The scrap dir (Wimp$ScrapDir) is not defined");
         
         when No_Files_In_Source_Dir =>
            Put_Line ("Error: No files in source directory");
            Syntax;
   
      end;
   end;

end Ada2Str;
