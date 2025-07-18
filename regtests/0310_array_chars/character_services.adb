------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2017-2025, AdaCore                     --
--                                                                          --
--  This is free software;  you can redistribute it  and/or modify it       --
--  under terms of the  GNU General Public License as published  by the     --
--  Free Software  Foundation;  either version 3,  or (at your option) any  --
--  later version.  This software is distributed in the hope  that it will  --
--  be useful, but WITHOUT ANY WARRANTY;  without even the implied warranty --
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU     --
--  General Public License for  more details.                               --
--                                                                          --
--  You should have  received  a copy of the GNU General  Public  License   --
--  distributed  with  this  software;   see  file COPYING3.  If not, go    --
--  to http://www.gnu.org/licenses for a complete copy of the license.      --
------------------------------------------------------------------------------

with Ada.Text_IO;

package body Character_Services is

   use Ada;

   ---------------------------
   -- Test_Character_Record --
   ---------------------------

   procedure Test_Character_Record (Value_Record : Character_Record_Type) is
   begin
      Text_IO.Put_Line ("VRC: " & Value_Record.Value);
   end Test_Character_Record;

   ------------------------------
   -- Test_Character_Parameter --
   ------------------------------

   procedure Test_Character_Parameter (Value_Param : Character) is
   begin
      Text_IO.Put_Line ("VPC: " & Value_Param);
   end Test_Character_Parameter;

   ---------------------------------
   -- Test_Array_Character_Record --
   ---------------------------------

   procedure Test_Array_Character_Record
     (Value_Record : Array_Character_Record_Type) is
   begin
      Text_IO.Put ("VRA:");

      for E of Value_Record.Value loop
         Text_IO.Put (' ' & E);
      end loop;

      Text_IO.New_Line;
   end Test_Array_Character_Record;

   ------------------------------------
   -- Test_Array_Character_Parameter --
   ------------------------------------

   procedure Test_Array_Character_Parameter
     (Value_Param : Array_Character_Type_Pkg.Vector) is
   begin
      Text_IO.Put ("VPA:");

      for E of Value_Param loop
         Text_IO.Put (' ' & E);
      end loop;

      Text_IO.New_Line;
   end Test_Array_Character_Parameter;

   ----------------------------------------
   -- Test_Array_Record_Character_Record --
   ----------------------------------------

   procedure Test_Array_Record_Character_Record
     (Value_Record : Array_Record_Character_Record_Type) is
   begin
      Text_IO.Put ("VRar:");

      for E of Value_Record.Value loop
         Text_IO.Put (' ' & E.Value);
      end loop;

      Text_IO.New_Line;
   end Test_Array_Record_Character_Record;

   -------------------------------------------
   -- Test_Array_Record_Character_Parameter --
   -------------------------------------------

   procedure Test_Array_Record_Character_Parameter
     (Value_Param : Array_Record_Character_Type_Pkg.Vector) is
   begin
      Text_IO.Put ("VPar:");

      for E of Value_Param loop
         Text_Io.Put (' ' & E.Value);
      end loop;

      Text_IO.New_Line;
   end Test_Array_Record_Character_Parameter;

end Character_Services;
