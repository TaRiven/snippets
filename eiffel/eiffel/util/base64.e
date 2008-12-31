indexing
   description: "Base64 stuff.";
class BASE64

creation {ANY}
   make

feature {ANY} -- Constructors

   make is
      -- Initialization
      local
         s: STRING;
      do
         init_const;
         s := encode(argument(1));
         io.put_string("Encoding:%N");
         io.put_string(argument(1));
         io.put_string("%NResults:%N");
         io.put_string(s);
         io.put_string("%N");
      end -- make

feature {ANY} -- Actual encode/decode stuff

   encode(in: STRING): STRING is
      -- Base64 Encode.
      local
         ab, bb, cb, db, tmpa, tmpb: BIT 8;
         i, o: INTEGER;
         a, b, c: CHARACTER;
         second, third: BOOLEAN;
      do
         !!Result.make(0);
         Result.clear;
         from
            i := 1;
            o := 0;
         until
            i > in.count
         loop
            a := in.item(i);
            ab := a.to_bit;
            if in.valid_index(i + 1) then
               second := true;
               b := in.item(i + 1);
               bb := b.to_bit;
               if in.valid_index(i + 2) then
                  third := true;
                  c := in.item(i + 2);
                  cb := c.to_bit;
               else
                  third := false;
               end;
            else
               second := false;
            end;
            tmpa := ab;
            Result.add_last(get_char(tmpa @>> 2));
            tmpa := (ab and lasttwo) @<< 4;
            if second then
               tmpb := bb @>> 4;
               Result.add_last(get_char(tmpb or tmpa));
               tmpa := bb and lastfour;
               tmpa := tmpa @<< 2;
               if third then
                  tmpb := cb and firsttwo;
                  tmpb := tmpb @>> 6;
                  Result.add_last(get_char(tmpa or tmpb));
                  Result.add_last(get_char(cb and lastsix));
               else
                  Result.add_last(get_char(tmpa));
                  Result.add_last('=');
               end;
            else
               Result.add_last(get_char(tmpa));
               Result.add_last('=');
               Result.add_last('=');
            end;
            i := i + 3;
            o := o + 4;
            if o \\ 76 = 0 then
               -- Base64 says lines should be 76 characters.
               Result.add_last('%N');
            end;
         end;
      end -- encode

   decode(in: STRING): STRING is
      -- Base64 Decode.
      do
      end -- decode

feature {NONE}

   get_char(b: BIT 8): CHARACTER is
      -- Get the character this bit pattern represents.
      local
         i: INTEGER;
      do
         i := b.to_integer;
         Result := charmap.item(i + 1);
      end -- get_char

   truncate(in: BIT 32): BIT 8 is
      -- Truncate a BIT 32 to a BIT 8
      do
         Result := in.to_integer.to_character.to_bit;
      end -- truncate

   init_const is
      -- Set up some constants, can't find a better way.
      once
         lasttwo := truncate(("00000011").binary_to_integer.to_bit);
         lastfour := truncate(("00001111").binary_to_integer.to_bit);
         lastsix := truncate(("00111111").binary_to_integer.to_bit);
         firsttwo := truncate(("11000000").binary_to_integer.to_bit);
      end -- init_const

   lasttwo: BIT 8;

   lastfour: BIT 8;

   lastsix: BIT 8;

   firsttwo: BIT 8;

   charmap: STRING is "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

end -- class BASE64
