program exemplo1 (input, output);
var k : integer;
procedure p(n, g: integer; z: boolean);
    var h: integer;
    begin
        if z then
            n := n +1;

        if n < 1 then
            g := g + n
        else
        begin
            h := g;
            p(n-1, h, false);
            g := h;
            p(n-2, g, false, 2)
        end;
        write(n, g)
    end;
begin
   k := 0;
   p(3, k, true)
end.
