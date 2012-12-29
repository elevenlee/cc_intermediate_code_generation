program parser_test;

var
  i,j,num  : integer;

function readint() : integer;
var
    a : integer;
begin
    readint := a
end;

function divides(x,y : integer) : boolean;
begin
  divides := y = x*(y div x) 
end;


begin
  num := readint();
  i := readint();
  for j := 1 to num do begin
    if divides(i,j) then 
	num := num + i
    end
end.
