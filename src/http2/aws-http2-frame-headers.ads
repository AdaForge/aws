------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                      Copyright (C) 2021, AdaCore                         --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with AWS.Headers;
with AWS.HTTP2.Connection;
with AWS.HTTP2.HPACK.Table;

with AWS.HTTP2.Frame.Priority;

private with AWS.Utils;

package AWS.HTTP2.Frame.Headers is

   type Object is new Frame.Object with private;

   function Read
     (Sock   : Net.Socket_Type'Class;
      Header : Frame.Object) return Object
     with Pre => Header.Is_Defined;
   --  Read an HEADERS frame from Sock return the corresponding object

   function Create
     (Table       : not null access HTTP2.HPACK.Table.Object;
      Settings    : not null access Connection.Object;
      Stream_Id   : HTTP2.Stream_Id;
      List        : AWS.Headers.List;
      End_Headers : Boolean := True) return Object
     with Post => (if End_Headers then Create'Result.Flags = End_Headers_Flag);
   --  Create an HEADERS frame with given content and stream id

   function Get_Priority (Self : Object) return HTTP2.Frame.Priority.Payload
     with Pre => Self.Is_Defined and then Self.Has_Flag (Priority_Flag);
   --  Return priority frame payload

   function Get
     (Self     : Object;
      Table    : not null access HTTP2.HPACK.Table.Object;
      Settings : not null access HTTP2.Connection.Object)
      return AWS.Headers.List;
   --  Get the header list out of the HEADERS frame. This reads the content of
   --  the payload and decode using HPACK.

   overriding procedure Send_Payload
     (Self : Object; Sock : Net.Socket_Type'Class);
   --  Send payload content

   overriding function Validate (Self : Object) return Error_Codes;

private

   --  RFC-7540 6.2
   --
   --  +---------------+
   --  |Pad Length? (8)|
   --  +-+-------------+-----------------------------------------------+
   --  |E|                 Stream Dependency? (31)                     |
   --  +-+-------------+-----------------------------------------------+
   --  |  Weight? (8)  |
   --  +-+-------------+-----------------------------------------------+
   --  |                   Header Block Fragment (*)                 ...
   --  +---------------------------------------------------------------+
   --  |                           Padding (*)                       ...
   --  +---------------------------------------------------------------+

   type Data_View_Kind is (Pad, Prio, Pad_Prio);

   type Data_View (Kind : Data_View_Kind := Pad) is record
      case Kind is
         when Pad      => Pad_Length    : Padding;

         when Prio     => Prio          : Frame.Priority.Payload;

         when Pad_Prio => PP_Pad_Length : Padding;
                          PP_Prio       : Frame.Priority.Payload;
      end case;
   end record with Unchecked_Union;

   type View_Kind is (Flat, Data);

   type Payload_View (Kind : View_Kind := Flat) is record
      case Kind is
         when Data => D : not null access Data_View;
         when Flat => S : Utils.Stream_Element_Array_Access;
      end case;
   end record with Unchecked_Union;

   type Object is new Frame.Object with record
      Data : Payload_View;
   end record;

   overriding procedure Release (Self : in out Object);

   function Get_Priority (Self : Object) return HTTP2.Frame.Priority.Payload is
     (if Self.Has_Flag (Padded_Flag)
      then Self.Data.D.PP_Prio
      else Self.Data.D.Prio);

end AWS.HTTP2.Frame.Headers;
