program p(input, output);
var a, b: integer;
begin
    a := 5;
    while a >= 1 do
        a := a - 1;

    b := 1;
    while ((a < 10) and (b > 0)) do
    begin
        a := a + 1;
        b := 0;
        while (b < a) do
            b := b + 1;
    end
end.