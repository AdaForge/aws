------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2000-2025, AdaCore                     --
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

pragma Ada_2022;

with Ada.Calendar.Arithmetic;
with Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones;
with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Tags;

with Unicode.CES.Basic_8bit;
with Unicode.CES.Utf8;

with AWS.Utils;
with SOAP.Message.XML;

package body SOAP.Utils is

   Last_Character_Index : constant Unicode_Char :=
                            Character'Pos (Character'Last);
   Utf8_Map             : Utf8_Map_Callback := Default_Utf8_Mapping'Access;

   ---------
   -- Any --
   ---------

   function Any
     (V         : Types.XSD_Any_Type;
      Name      : String := "item";
      Type_Name : String := Types.XML_String;
      NS        : Name_Space.Object := Name_Space.No_Name_Space)
      return Types.XSD_Any_Type is
   begin
      return SOAP.Types.Any (Types.Object'Class (V), Name, Type_Name, NS);
   end Any;

   ------------
   -- AnyURI --
   ------------

   function AnyURI
     (V         : Unbounded_String;
      Name      : String := "item";
      Type_Name : String := Types.XML_Any_URI;
      NS        : Name_Space.Object := Name_Space.No_Name_Space)
      return Types.XSD_Any_URI is
   begin
      return Types.AnyURI (To_String (V), Name, Type_Name, NS);
   end AnyURI;

   -------
   -- C --
   -------

   function C
     (V         : Character;
      Name      : String := "item";
      Type_Name : String := "Character";
      NS        : Name_Space.Object := Name_Space.No_Name_Space)
      return Types.XSD_String is
   begin
      return Types.S (String'[V], Name, Type_Name, NS);
   end C;

   ----------
   -- Date --
   ----------

   function Date
     (Date, Name  : String;
      Type_Name   : String := Types.XML_Date)
      return Types.XSD_Date
   is
      use Ada;
      use Ada.Calendar;
      use Ada.Calendar.Formatting;
      use type Ada.Calendar.Time_Zones.Time_Offset;

      --  A time-zone starts with either + | - or Z

      TZ_Pattern : constant Strings.Maps.Character_Set :=
                   Strings.Maps.To_Set ("+-Z");

      First      : constant Positive := Date'First;

      subtype Year_Range      is Positive range First      .. First + 3;
      subtype Month_Range     is Positive range First + 5  .. First + 6;
      subtype Day_Range       is Positive range First + 8  .. First + 9;

      --  If we have franctional second skip them

      TZ_Start : constant Natural :=
                   Strings.Fixed.Index
                     (Date, TZ_Pattern, From => Day_Range'Last);

      TZ_First : constant Positive :=
                   (if TZ_Start /= 0 then TZ_Start else Date'Last + 1);

      subtype TZ_Type_Range   is Positive range TZ_First     .. TZ_First;
      subtype TZ_Hour_Range   is Positive range TZ_First + 1 .. TZ_First + 2;
      subtype TZ_Minute_Range is Positive range TZ_First + 4 .. TZ_First + 5;

      T          : Calendar.Time;
      TZ         : Time_Zones.Time_Offset := 0;

   begin
      --  data format is (-)CCYY-MM-DD[[+|-]hh:mm | Z]

      --  Check if a time-zone is specified

      if Date'Last >= TZ_Type_Range'Last then
         --  Time zone specified

         if Date'Last >= TZ_Hour_Range'Last then
            TZ := Time_Zones.Time_Offset'Value (Date (TZ_Hour_Range)) * 60;

            if Date'Last = TZ_Minute_Range'Last then
               TZ := TZ
                 + Time_Zones.Time_Offset'Value (Date (TZ_Minute_Range));
            end if;

            if Date (TZ_Type_Range) = "-" then
               TZ := -TZ;
            end if;
         end if;
      end if;

      T := Time_Of (Year       => Year_Number'Value (Date (Year_Range)),
                    Month      => Month_Number'Value (Date (Month_Range)),
                    Day        => Day_Number'Value (Date (Day_Range)),
                    Hour       => Hour_Number'First,
                    Minute     => Minute_Number'First,
                    Second     => Second_Number'First,
                    Sub_Second => 0.0,
                    Time_Zone  => TZ);

      return Types.TD (Types.Local_Date (T), Name, Type_Name => Type_Name);
   end Date;

   --------------------------
   -- Default_Utf8_Mapping --
   --------------------------

   function Default_Utf8_Mapping (C : Unicode_Char) return Character is
      pragma Unreferenced (C);
      Invalid_Utf8_Character : constant Character := '?';
   begin
      return Invalid_Utf8_Character;
   end Default_Utf8_Mapping;

   --------------
   -- Duration --
   --------------

   function Duration
     (D, Name   : String;
      Type_Name : String := Types.XML_Duration)
      return Types.XSD_Duration
   is
      use Ada;
      use Ada.Calendar;
      use Ada.Calendar.Arithmetic;

      use type Strings.Maps.Character_Set;

      subtype S_Duration is Standard.Duration;

      Numeric_Set : constant Strings.Maps.Character_Set :=
                      Strings.Maps.Constants.Decimal_Digit_Set
                      or Strings.Maps.To_Set (".");

      Minute    : constant := 60;
      Hour      : constant := 60 * Minute;

      Base      : constant Calendar.Time := Calendar.Clock;
      Negative  : constant Boolean := D (D'First) = '-';

      Next      : Calendar.Time;
      B_Year    : Calendar.Year_Number;
      B_Month   : Positive;
      B_Day     : Calendar.Day_Number;
      B_Seconds : Standard.Duration;

      Time_Mode : Boolean := False;
      N_Day     : Calendar.Arithmetic.Day_Count := 0;
      Seconds   : S_Duration := 0.0;
      K         : Positive := D'First + (if Negative then 2 else 1);
      L         : Natural;

   begin
      Calendar.Split (Base, B_Year, B_Month, B_Day, B_Seconds);

      --  Parse XSD duration

      while K < D'Last loop
         --  Time separator found, skip it

         if D (K) = 'T' then
            Time_Mode := True;
            K := @ + 1;
         end if;

         --  Check for next non-digit character, all chunk are <n>[K] where
         --  K is a letter specifiying the actual part of the duration.

         L := Strings.Fixed.Index
           (D,
            From => K,
            Set  => Numeric_Set,
            Test => Strings.Outside);

         exit when L = 0;

         declare
            Value : constant S_Duration :=  S_Duration'Value (D (K .. L - 1));
            Key   : constant Character := D (L);
         begin
            case Key is
               when 'Y' =>
                  B_Year := @ + Natural (Value);

               when 'M' =>
                  if Time_Mode then
                     Seconds := @ + S_Duration (Value * Minute);

                  else
                     B_Month := @ + Natural (Value);

                     while B_Month > 12 loop
                        B_Year := @ + 1;
                        B_Month := @ - 12;
                     end loop;
                  end if;

               when 'D' =>
                  N_Day := Calendar.Arithmetic.Day_Count (Value);

               when 'H' =>
                  Seconds := @ + Value * Hour;

               when 'S' =>
                  Seconds := @ + Value;

               when others =>
                  null;
            end case;
         end;

         K := L + 1;
      end loop;

      --  Now compute the date startinig from base and adding the duration

      --  First we take into accound the Year and Month and keep the other
      --  parameters.

      Next := Calendar.Time_Of (B_Year, B_Month, B_Day, B_Seconds);

      --  Then we need to add the Second and Day count

      Next := @ + N_Day + Seconds;

      declare
         Result : Standard.Duration := Next - Base;
      begin
         if Negative then
            Result := -@;
         end if;

         return Types.D (Result, Name, Type_Name);
      end;
   end Duration;

   ------------
   -- Encode --
   ------------

   procedure Encode
     (S      : Unbounded_String;
      Result : in out Unbounded_String)
   is
      Ch : Character;
   begin
      for K in 1 .. Length (S) loop
         Ch := Element (S, K);

         case Ch is
            when '<'    => Append (Result, "&lt;");
            when '>'    => Append (Result, "&gt;");
            when '&'    => Append (Result, "&amp;");
            when '''    => Append (Result, "&apos;");
            when '"'    => Append (Result, "&quot;");
            when Character'Val (0) .. Character'Val (31) =>
               Append (Result, "&#");
               Append (Result, AWS.Utils.Image (Natural (Character'Pos (Ch))));
               Append (Result, ';');
            when others => Append (Result, Ch);
         end case;
      end loop;
   end Encode;

   function Encode (Str : String) return String is
      Result : Unbounded_String;
   begin
      Encode (To_Unbounded_String (Str), Result);
      return To_String (Result);
   end Encode;

   ---------------
   -- From_Utf8 --
   ---------------

   function From_Utf8 (Str : String) return String is
      A : String_Access := From_Utf8 (Str);
      R : constant String := A.all;
   begin
      Free (A);
      return R;
   end From_Utf8;

   function From_Utf8 (Str : Unbounded_String) return Unbounded_String is
      use type Unicode_Char;

      Idx      : Integer := 1;
      Buf      : String (1 .. 6);
      Buf_Last : Integer := 0;
      Ch32     : Unicode_Char;
      W        : Integer;
      Result   : Unbounded_String;
   begin
      loop
         while Idx <= Length (Str)
           and then Buf_Last < Buf'Last
         loop
            Buf (Buf_Last + 1) := Element (Str, Idx);
            Idx := @ + 1;
            Buf_Last := @ + 1;
         end loop;

         exit when Buf_Last = 0;

         W := 1;
         Unicode.CES.Utf8.Read (Buf, W, Ch32);
         W := @ - 1;

         Buf_Last := @ - W;

         for I in 1 .. Buf_Last loop
            Buf (I) := Buf (I + W);
         end loop;

         if Ch32 > Last_Character_Index then
            Append (Result, Utf8_Map (Ch32));
         else
            Append (Result, Character'Val (Ch32));
         end if;
      end loop;

      return Result;
   end From_Utf8;

   function From_Utf8 (Str : String) return String_Access is
      use type Unicode_Char;

      Result : String_Access := new String (1 .. 2000);
      Last   : Integer := 0;

      procedure Append (Ch : Character) with Inline;
      --  Append Ch into Result, adjust Result size if needed

      procedure Adjust_Result with Inline;
      --  Adjust final Result to the right size

      -------------------
      -- Adjust_Result --
      -------------------

      procedure Adjust_Result is
         Old : String_Access;
      begin
         if Last /= Result'Last then
            Old := Result;
            Result := new String (1 .. Last);
            Result.all := Old (1 .. Last);
            Free (Old);
         end if;
      end Adjust_Result;

      ------------
      -- Append --
      ------------

      procedure Append (Ch : Character) is
         Old : String_Access;
      begin
         if Last >= Result'Last then
            Old := Result;
            Result := new String (1 .. Old'Last * 2);
            Result (1 .. Old'Last) := Old.all;
            Free (Old);
         end if;

         Last := @ + 1;
         Result (Last) := Ch;
      end Append;

      Idx      : Integer := Str'First;
      Buf      : String (1 .. 6);
      Buf_Last : Integer := 0;
      Ch32     : Unicode_Char;
      W        : Integer;

   begin
      loop
         while Idx <= Str'Last and then Buf_Last < Buf'Last loop
            Buf (Buf_Last + 1) := Str (Idx);
            Idx := @ + 1;
            Buf_Last := @ + 1;
         end loop;

         exit when Buf_Last = 0;

         W := 1;
         Unicode.CES.Utf8.Read (Buf, W, Ch32);
         W := @ - 1;

         Buf_Last := @ - W;

         for I in 1 .. Buf_Last loop
            Buf (I) := Buf (I + W);
         end loop;

         if Ch32 > Last_Character_Index then
            Append (Utf8_Map (Ch32));
         else
            Append (Character'Val (Ch32));
         end if;
      end loop;

      Adjust_Result;
      return Result;
   end From_Utf8;

   ---------
   -- Get --
   ---------

   function Get (Item : Types.Object'Class) return Unbounded_String is
   begin
      return To_Unbounded_String (String'(Types.Get (Item)));
   end Get;

   function Get (Item : Types.Object'Class) return Character is
      Str : constant String := String'(Types.Get (Item));
   begin
      --  Str is empty if passed as optional parameter (xsi:nil)
      if Str'Length = 0 then
         return ASCII.NUL;
      else
         return Str (Str'First);
      end if;
   end Get;

   function Get (Item : Types.Object'Class) return String is
      Enum : constant Types.SOAP_Enumeration :=
               Types.SOAP_Enumeration (Item);
   begin
      return Types.Image (Enum);
   end Get;

   --------------------------
   -- Is_Ada_Reserved_Word --
   --------------------------

   function Is_Ada_Reserved_Word (Name : String) return Boolean is
      N : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      if N in "abort" | "else" | "new" | "return" | "abs" | "elsif"
        | "not" | "reverse" | "abstract" | "end" | "null" | "accept"
        | "entry" | "select" | "access" | "exception" | "separate"
        | "aliased" | "exit" | "of" | "subtype" | "all" | "or"
        | "and" | "for" | "others" | "tagged" | "array"
        | "function" | "out" | "task" | "at" | "terminate" | "generic"
        | "package" | "then" | "begin" | "goto" | "pragma" | "type"
        | "body" | "private" | "if" | "procedure" | "case" | "in"
        | "protected" | "until" | "constant" | "is" | "use"
        | "raise" | "declare" | "range" | "when" | "delay" | "limited"
        | "record" | "while" | "delta" | "loop" | "rem" | "with"
        | "digits" | "renames" | "do" | "mod" | "requeue" | "xor"
        | "synchronized" | "overriding" | "interface" | "some"
      then
         return True;
      else
         return False;
      end if;
   end Is_Ada_Reserved_Word;

   -----------
   -- No_NS --
   -----------

   function No_NS (Name : String) return String is
      K : constant Natural := Ada.Strings.Fixed.Index (Name, ":");
   begin
      if K = 0 then
         return Name;
      else
         return Name (K + 1 .. Name'Last);
      end if;
   end No_NS;

   --------
   -- NS --
   --------

   function NS (Name : String) return String is
      K : constant Natural := Ada.Strings.Fixed.Index (Name, ":");
   begin
      if K = 0 then
         return "";
      else
         return Name (Name'First .. K - 1);
      end if;
   end NS;

   ------------------
   -- Set_Utf8_Map --
   ------------------

   procedure Set_Utf8_Map (Callback : Utf8_Map_Callback) is
   begin
      Utf8_Map := Callback;
   end Set_Utf8_Map;

   ------------------
   -- SOAP_Wrapper --
   ------------------

   function SOAP_Wrapper
     (Request : AWS.Status.Data;
      Schema  : WSDL.Schema.Definition := WSDL.Schema.Empty)
      return AWS.Response.Data
   is
      SOAPAction : constant String := AWS.Status.SOAPAction (Request);
   begin
      if SOAPAction /= No_SOAPAction then
         declare
            Payload_Data : constant Unbounded_String :=
                             AWS.Status.Payload (Request);
            Payload      : constant Message.Payload.Object :=
                             Message.XML.Load_Payload
                               (Payload_Data, Schema => Schema);
         begin
            return SOAP_CB (SOAPAction, Payload, Request);
         end;

      else
         raise Constraint_Error;
      end if;
   end SOAP_Wrapper;

   ---------
   -- Tag --
   ---------

   function Tag (Name : String; Start : Boolean) return String is
   begin
      if Start then
         return '<' & Name & '>';
      else
         return "</" & Name & '>';
      end if;
   end Tag;

   ----------
   -- Time --
   ----------

   function Time
     (Time, Name  : String;
      Type_Name   : String := Types.XML_Time)
      return Types.XSD_Time
   is
      use Ada;
      use Ada.Calendar;
      use Ada.Calendar.Formatting;
      use type Ada.Calendar.Time_Zones.Time_Offset;

      --  A time-zone starts with either + | - or Z

      TZ_Pattern : constant Strings.Maps.Character_Set :=
                   Strings.Maps.To_Set ("+-Z");

      --  A time-instant string may start with a minus sign to specify a year
      --  Before Common Era. We do not support such date here and so we just
      --  skip the minus sign if present. Also not that a plus sign is not
      --  allowed.

      First      : constant Positive :=
                     (if Time'Length > 1 and then Time (Time'First) = '-'
                      then Time'First + 1
                      else Time'First);

      subtype Hour_Range      is Positive range First     .. First + 1;
      subtype Minute_Range    is Positive range First + 3 .. First + 4;
      subtype Second_Range    is Positive range First + 6 .. First + 7;

      --  If we have franctional second skip them

      TZ_Start : constant Natural :=
                   Strings.Fixed.Index
                     (Time, TZ_Pattern, From => Second_Range'Last);

      TZ_First : constant Positive :=
                   (if TZ_Start /= 0 then TZ_Start else Time'Last + 1);

      subtype TZ_Type_Range   is Positive range TZ_First     .. TZ_First;
      subtype TZ_Hour_Range   is Positive range TZ_First + 1 .. TZ_First + 2;
      subtype TZ_Minute_Range is Positive range TZ_First + 4 .. TZ_First + 5;

      T          : Calendar.Time;
      TZ         : Time_Zones.Time_Offset := 0;
      Sub_Second : Second_Duration := 0.0;

   begin
      --  time format is (-)hh:mm:ss(.sss)[[+|-]hh:mm | Z]

      --  Check if an optional fractional second part is present

      if Second_Range'Last + 1 < TZ_Type_Range'First then
         Sub_Second := Second_Duration'Value
           (Time (Second_Range'Last + 1 .. TZ_Type_Range'First - 1));
      end if;

      --  Check if a time-zone is specified

      if Time'Last >= TZ_Type_Range'Last then
         --  Time zone specified

         if Time'Last >= TZ_Hour_Range'Last then
            TZ := Time_Zones.Time_Offset'Value (Time (TZ_Hour_Range)) * 60;

            if Time'Last = TZ_Minute_Range'Last then
               TZ := TZ
                 + Time_Zones.Time_Offset'Value (Time (TZ_Minute_Range));
            end if;

            if Time (TZ_Type_Range) = "-" then
               TZ := -TZ;
            end if;
         end if;
      end if;

      T := Time_Of (Year       => Year_Number'First,
                    Month      => Month_Number'First,
                    Day        => Day_Number'First,
                    Hour       => Hour_Number'Value (Time (Hour_Range)),
                    Minute     => Minute_Number'Value (Time (Minute_Range)),
                    Second     => Second_Number'Value (Time (Second_Range)),
                    Sub_Second => Sub_Second,
                    Time_Zone  => TZ);

      return Types.TT (Types.Local_Time (T), Name, Type_Name => Type_Name);
   end Time;

   ------------------
   -- Time_Instant --
   ------------------

   function Time_Instant
     (TI, Name  : String;
      Type_Name : String := Types.XML_Time_Instant)
      return Types.XSD_Time_Instant
   is
      use Ada;
      use Ada.Calendar;
      use Ada.Calendar.Formatting;
      use type Ada.Calendar.Time_Zones.Time_Offset;

      --  A time-zone starts with either + | - or Z

      TZ_Pattern : constant Strings.Maps.Character_Set :=
                   Strings.Maps.To_Set ("+-Z");

      --  A time-instant string may start with a minus sign to specify a year
      --  Before Common Era. We do not support such date here and so we just
      --  skip the minus sign if present. Also not that a plus sign is not
      --  allowed.

      First      : constant Positive :=
                     (if TI'Length > 1 and then TI (TI'First) = '-'
                      then TI'First + 1
                      else TI'First);

      subtype Year_Range      is Positive range First      .. First + 3;
      subtype Month_Range     is Positive range First + 5  .. First + 6;
      subtype Day_Range       is Positive range First + 8  .. First + 9;
      subtype Hour_Range      is Positive range First + 11 .. First + 12;
      subtype Minute_Range    is Positive range First + 14 .. First + 15;
      subtype Second_Range    is Positive range First + 17 .. First + 18;

      --  If we have franctional second skip them

      TZ_Start : constant Natural :=
                   Strings.Fixed.Index
                     (TI, TZ_Pattern, From => Second_Range'Last);

      TZ_First : constant Positive :=
                   (if TZ_Start /= 0 then TZ_Start else TI'Last + 1);

      subtype TZ_Type_Range   is Positive range TZ_First     .. TZ_First;
      subtype TZ_Hour_Range   is Positive range TZ_First + 1 .. TZ_First + 2;
      subtype TZ_Minute_Range is Positive range TZ_First + 4 .. TZ_First + 5;

      T          : Calendar.Time;
      TZ         : Time_Zones.Time_Offset := 0;
      Sub_Second : Second_Duration := 0.0;

   begin
      --  timeInstant format is (-)CCYY-MM-DDThh:mm:ss(.sss)[[+|-]hh:mm | Z]

      --  Check if an optional fractional second part is present

      if Second_Range'Last + 1 < TZ_Type_Range'First then
         Sub_Second := Second_Duration'Value
           (TI (Second_Range'Last + 1 .. TZ_Type_Range'First - 1));
      end if;

      --  Check if a time-zone is specified

      if TI'Last >= TZ_Type_Range'Last then
         --  Time zone specified

         if TI'Last >= TZ_Hour_Range'Last then
            TZ := Time_Zones.Time_Offset'Value (TI (TZ_Hour_Range)) * 60;

            if TI'Last = TZ_Minute_Range'Last then
               TZ := @ + Time_Zones.Time_Offset'Value (TI (TZ_Minute_Range));
            end if;

            if TI (TZ_Type_Range) = "-" then
               TZ := -@;
            end if;
         end if;
      end if;

      T := Time_Of (Year       => Year_Number'Value (TI (Year_Range)),
                    Month      => Month_Number'Value (TI (Month_Range)),
                    Day        => Day_Number'Value (TI (Day_Range)),
                    Hour       => Hour_Number'Value (TI (Hour_Range)),
                    Minute     => Minute_Number'Value (TI (Minute_Range)),
                    Second     => Second_Number'Value (TI (Second_Range)),
                    Sub_Second => Sub_Second,
                    Time_Zone  => TZ);

      return Types.T (Types.Local_Date_Time (T), Name, Type_Name => Type_Name);
   end Time_Instant;

   -------------
   -- To_Name --
   -------------

   function To_Name (Q_Name : String) return String is
      use Ada;
   begin
      return Strings.Fixed.Translate
        (Q_Name, Strings.Maps.To_Mapping (":", "_"));
   end To_Name;

   -------------------
   -- To_Object_Set --
   -------------------

   function To_Object_Set
     (From : T_Array;
      NS   : Name_Space.Object) return Types.Object_Set
   is
      use SOAP.Types;
      Result : Types.Object_Set (From'Range);
   begin
      for K in From'Range loop
         Result (K) :=
           +Get (From (K), Name => E_Name, Type_Name => Type_Name, NS => NS);
      end loop;

      return Result;
   end To_Object_Set;

   ---------------------
   -- To_Object_Set_C --
   ---------------------

   function To_Object_Set_C
     (From : T_Array;
      NS   : Name_Space.Object) return Types.Object_Set
   is
      use SOAP.Types;
      Result : Types.Object_Set (1 .. Integer (From'Last));
   begin
      for K in From'Range loop
         Result (Integer (K)) :=
           +Get (From (K), Name => E_Name, Type_Name => Type_Name, NS => NS);
      end loop;

      return Result;
   end To_Object_Set_C;

   ---------------------
   -- To_Object_Set_V --
   ---------------------

   function To_Object_Set_V
     (From : Vector.Vector;
      NS   : Name_Space.Object) return Types.Object_Set
   is
      use SOAP.Types;
      Result : Types.Object_Set (1 .. Integer (From.Length));
   begin
      for K in Result'Range loop
         Result (K) :=
           +Get (From (K), Name => E_Name, Type_Name => Type_Name, NS => NS);
      end loop;

      return Result;
   end To_Object_Set_V;

   ----------------
   -- To_T_Array --
   ----------------

   function To_T_Array (From : Types.Object_Set) return T_Array is
      use type Ada.Tags.Tag;
      use SOAP.Types;
      Result : T_Array (From'Range);
   begin
      for K in From'Range loop
         declare
            E : constant SOAP.Types.Object'Class := -From (K);
         begin
            --  A single element which is a SOAP_Set, this is the
            --  vector to be converted.
            if E'Tag = SOAP.Types.SOAP_Set'Tag
              and then From'Length = 1
            then
               return To_T_Array (V (SOAP.Types.SOAP_Set (E)));

            --  Likewise for a SOAP_Array
            elsif E'Tag = SOAP.Types.SOAP_Array'Tag
              and then From'Length = 1
            then
               return To_T_Array (V (SOAP.Types.SOAP_Array (E)));

            else
               Result (K) := Get (E);
            end if;
         end;
      end loop;

      return T_Array'(Result);
   end To_T_Array;

   ------------------
   -- To_T_Array_C --
   ------------------

   function To_T_Array_C (From : Types.Object_Set) return T_Array is
      use type Ada.Tags.Tag;
      use SOAP.Types;
      Result : T_Array;
   begin
      for K in Result'Range loop
         declare
            E : constant SOAP.Types.Object'Class := -From (Integer (K));
         begin
            --  A single element which is a SOAP_Set, this is the
            --  vector to be converted.
            if E'Tag = SOAP.Types.SOAP_Set'Tag
              and then From'Length = 1
            then
               return To_T_Array_C (V (SOAP.Types.SOAP_Set (E)));

            --  Likewise for a SOAP_Array
            elsif E'Tag = SOAP.Types.SOAP_Array'Tag
              and then From'Length = 1
            then
               return To_T_Array_C (V (SOAP.Types.SOAP_Array (E)));

            else
               Result (K) := Get (E);
            end if;
         end;
      end loop;

      return Result;
   end To_T_Array_C;

   -------------
   -- To_Utf8 --
   -------------

   function To_Utf8 (Str : String) return String is
   begin
      return Unicode.CES.Utf8.From_Utf32
        (Unicode.CES.Basic_8bit.To_Utf32 (Str));
   end To_Utf8;

   function To_Utf8 (Str : Unbounded_String) return Unbounded_String is
      Chars  : String (1 .. 6);
      Idx    : Integer;
      Result : Unbounded_String;
   begin
      for I in 1 .. Length (Str) loop
         Idx := 0;
         Unicode.CES.Utf8.Encode
            (Character'Pos (Element (Str, I)), Chars, Idx);
         Append (Result, Chars (1 .. Idx));
      end loop;

      return Result;
   end To_Utf8;

   ---------------
   -- To_Vector --
   ---------------

   function To_Vector (From : Types.Object_Set) return Vector.Vector is
      use type Ada.Tags.Tag;
      use SOAP.Types;
      Result : Vector.Vector;
   begin
      for K in From'Range loop
         declare
            E : constant SOAP.Types.Object'Class := -From (K);
         begin
            --  A single element which is a SOAP_Set, this is the
            --  vector to be converted.
            if E'Tag = SOAP.Types.SOAP_Set'Tag
              and then From'Length = 1
            then
               return To_Vector (V (SOAP.Types.SOAP_Set (E)));

            --  Likewise for a SOAP_Array
            elsif E'Tag = SOAP.Types.SOAP_Array'Tag
              and then From'Length = 1
            then
               return To_Vector (V (SOAP.Types.SOAP_Array (E)));

            else
               Result.Append (Get (E));
            end if;
         end;
      end loop;

      return Result;
   end To_Vector;

   --------
   -- US --
   --------

   function US
     (V         : Unbounded_String;
      Name      : String := "item";
      Type_Name : String := Types.XML_String;
      NS        : Name_Space.Object := Name_Space.No_Name_Space)
      return Types.XSD_String is
   begin
      return Types.S (To_String (V), Name, Type_Name, NS);
   end US;

   -------
   -- V --
   -------

   function V (O : Types.XSD_String) return Unbounded_String is
   begin
      return To_Unbounded_String (Types.V (O));
   end V;

   function V (O : Types.XSD_String) return Character is
   begin
      return Types.V (O) (1);
   end V;

   -------------
   -- With_NS --
   -------------

   function With_NS (NS, Name : String) return String is
      use Ada;
      K : Natural;
   begin
      if NS = "" then
         return Name;

      else
         K := Strings.Fixed.Index (Name, ":");

         if K = 0 then
            K := Name'First;
         else
            K := @ + 1;
         end if;

         return NS & ':' & Name (K .. Name'Last);
      end if;
   end With_NS;

end SOAP.Utils;
