------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                        Copyright (C) 2015, AdaCore                       --
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

with AWS.Config.Set;
with AWS.Server.Status;
with SOAP.Dispatchers.Callback;

with Simpledocservice2.Client;
with Simpledocservice2.Server;
with Simpledocservice2.Types;

with SD2_Server_CB;

procedure SimpleDoc2 is

   use Ada.Text_IO;
   use AWS;

   use Simpledocservice2.Client;
   use Simpledocservice2.Server;
   use Simpledocservice2.Types;

   H_Server : AWS.Server.HTTP;
   Conf     : Config.Object := Config.Get_Current;
   H        : SOAP.Dispatchers.Callback.Handler;

begin
   H := SOAP.Dispatchers.Callback.Create
     (SD2_Server_Cb.CB'Access, SD2_Server_Cb.S_CB'Access);

   Config.Set.Server_Host (Conf, "localhost");
   Config.Set.Server_Port (Conf, 0);

   AWS.Server.Start (H_Server, H, Conf);

   Call (2, 8.1, Endpoint => Server.Status.Local_URL (H_Server));

   AWS.Server.Shutdown (H_Server);
end SimpleDoc2;
