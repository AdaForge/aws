------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                    Copyright (C) 2017-2025, AdaCore                      --
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

pragma Ada_2022;

with Ada.Calendar;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with AWS.Client;

with API;
with api_service.Client;
with api_service.Types;

procedure NS_Rename_Arr_Rec_Client (Client : AWS.Client.HTTP_Connection) is

   use Ada.Strings.Unbounded;
   use Ada.Text_IO;

   use api_service.Client;
   use api_service.Types;

   R : R_Type := (To_Unbounded_String ("19"), To_Unbounded_String ("17"));
   A : API.Arr_Pkg.Vector := [1 => R];
   P : Part_Type := (V  => 1,
                     C1 => To_Unbounded_String ("c1"),
                     It => A,
                     C2 => To_Unbounded_String ("c2"));

begin
   Call (Client, P);
end NS_Rename_Arr_Rec_Client;
