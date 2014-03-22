program p(input, output);
var a, b: integer;
procedure v(x,y: integer; z: integer);
var d: integer;
begin
    d := 5;
    a := x + y;
    b := x + z;
end;
begin
    v(3, 2, 5);
    write(a, b)
end.