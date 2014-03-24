program exemplo9 (input, output);
var x, y:  integer;
    procedure p(var t: integer; n: integer);
    begin
        if n > 0 then
        begin
            t := t + 2;
            p(t, n-1)
        end
   end;
begin
    x := 3;
    p(x, 12);
    write(x)
end.
