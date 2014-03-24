program p(input, output);
var a: integer;
procedure p(var a: integer);
    var b: integer;
    begin
        b := 2;
        a := a + b;
    end;
begin
    a := 5;
    p(a);
    write(a);
end.