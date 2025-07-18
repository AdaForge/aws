------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2003-2025, AdaCore                     --
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

package body WSDL_2 is

   use Ada;

   ---------
   -- Add --
   ---------

   function Add (A, B : Complex) return Complex is
   begin
      return (A.X + B.X, A.Y + B.Y);
   end Add;

   ---------
   -- Sum --
   ---------

   function Sum (T : Table.Vector) return Integer is
      Result : Integer := 0;
   begin
      for E of T loop
         Result := Result + E;
      end loop;
      return Result;
   end Sum;

end WSDL_2;
