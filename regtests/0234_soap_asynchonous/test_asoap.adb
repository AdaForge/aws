------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                       Copyright (C) 2013, AdaCore                        --
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
with Ada.Exceptions;

with AWS.Server.Status;
with AWS.Client;
with AWS.Status;
with AWS.MIME;
with AWS.Response;
with AWS.Parameters;
with AWS.Messages;

with SOAP.Client;
with SOAP.Message.Payload;
with SOAP.Message.Response;
with SOAP.Message.XML;
with SOAP.Parameters;
with SOAP.Types;

procedure Test_ASOAP is

   use Ada;
   use Ada.Text_IO;
   use AWS;

   function CB      (Request : Status.Data) return Response.Data;
   function SOAP_CB (Request : Status.Data) return Response.Data;

   HTTP : Server.HTTP;

   --------
   -- CB --
   --------

   function CB (Request : Status.Data) return Response.Data is
      SOAP_Action : constant String := Status.SOAPAction (Request);
   begin
      if SOAP_Action = "/simple1" or else SOAP_Action = "/simple2" then
         return SOAP_CB (Request);

      else
         Put_Line ("This is not a known SOAP request : " & SOAP_Action);
         return Response.Build
           (MIME.Text_HTML, SOAP_Action & " not handler", Messages.S404);
      end if;
   end CB;

   -------------
   -- Request --
   -------------

   procedure Request (Str : String; Asynchronous : Boolean) is
      use SOAP.Types;
      use type SOAP.Parameters.List;

      P_Set   : constant SOAP.Parameters.List := +S (Str, "str");
      Payload : SOAP.Message.Payload.Object;
   begin
      Payload := SOAP.Message.Payload.Build (Str, P_Set);

      declare
         Response : constant SOAP.Message.Response.Object'Class :=
                      SOAP.Client.Call
                        (AWS.Server.Status.Local_URL (HTTP) & "/" & Str,
                         Payload,
                         SOAPAction   => "/" & Str,
                         Asynchronous => Asynchronous);
      begin
         Text_IO.Put_Line ("Error? " & Boolean'Image (Response.Is_Error));
      end;
   end Request;

   -------------
   -- SOAP_CB --
   -------------

   function SOAP_CB (Request : Status.Data) return Response.Data is
      use SOAP.Types;
      use SOAP.Parameters;

      Payload      : constant SOAP.Message.Payload.Object :=
                       SOAP.Message.XML.Load_Payload
                         (AWS.Status.Payload (Request));

      SOAP_Proc    : constant String :=
                       SOAP.Message.Payload.Procedure_Name (Payload);

      Parameters   : constant SOAP.Parameters.List :=
                       SOAP.Message.Parameters (Payload);

      Response     : SOAP.Message.Response.Object;
      R_Parameters : SOAP.Parameters.List;

   begin
      Text_IO.Put_Line ("Proc " & SOAP_Proc);

      if SOAP_Proc = "simple1" then
         Response := SOAP.Message.Response.From (Payload);

         declare
            Str : constant String := SOAP.Parameters.Get (Parameters, "str");
         begin
            Text_IO.Put_Line ("S: [" & Str & "]");

            R_Parameters := +I (Str'Length, "result");
         end;

         SOAP.Message.Set_Parameters (Response, R_Parameters);

         return SOAP.Message.Response.Build (Response);

      else
         return AWS.Response.Acknowledge (Messages.S200);
      end if;
   end SOAP_CB;

begin
   Put_Line ("Start main, wait for server to start...");

   Server.Start
     (HTTP, "asynchronous_soap_demo",
      CB'Unrestricted_Access,
      Port           => 0,
      Max_Connection => 5);

   Put_Line ("Server started");
   New_Line;

   Request ("simple1", Asynchronous => False);
   Request ("simple2", Asynchronous => True);

   Server.Shutdown (HTTP);

exception
   when E : others =>
      Put_Line ("Main Error " & Exceptions.Exception_Information (E));
      Server.Shutdown (HTTP);
end Test_ASOAP;