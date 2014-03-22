program p(input, output);
var a, b: integer;
begin
    a := 5;
    if a >= 1 then
        a := a - 1;

    b := 1;
    if ((a < 10) and (b > 0)) then
    begin
        write(a);
        a := a + 1;
        b := 2;
        if (b > a) then
            b := b + 1
        else
        begin
            a := 10;
            write(b+1);
        end
    end;

    b := a + b;
    write(a, b)
end.