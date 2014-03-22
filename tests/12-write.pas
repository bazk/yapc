program p(input, output);
var a, b: integer;
begin
    a := 5;
    if a >= 1 then
        a := a - 1;

    b := 1;
    if ((a < 10) && (b > 0)) then
    begin
        writeln(a);
        a := a + 1;
        b := 0;
        if (b > a) then
            b := b + 1
        else
        begin
            a := 10;
            writeln(b);
        end
    end;

    b := a + b;
    writeln(a)
end.