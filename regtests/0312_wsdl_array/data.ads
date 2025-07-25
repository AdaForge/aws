------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                    Copyright (C) 2018-2025, AdaCore                      --
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

with Ada.Containers.Vectors;

package Data is

   package Int_Array_Pkg is
     new Ada.Containers.Vectors (Positive, Integer);

   type Rec is record
      A : Integer;
      B : Character;
   end record;

   package Rec_Array_Pkg is
     new Ada.Containers.Vectors (Positive, Rec);

   procedure Call
     (A1 : Int_Array_Pkg.Vector;
      A2 : Rec_Array_Pkg.Vector);

end Data;
