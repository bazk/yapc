program labels(input, output);
var x, y: integer;
procedure p (s: integer; var t :integer);
   label 100;
   begin
      100: t := t * s;
      s := s - 1;

      if s > 0 then
         goto 100;

   end;
begin
   read(x, y);
   p(x, y);
   write(y)
end.
