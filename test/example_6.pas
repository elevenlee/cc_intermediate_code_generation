{ 
	This program is error-free.
}

program errorfree;
type
	s = string;
	in = integer;
var
	z : in;
	m : in;

function foo(a : in) : in; 
begin
   a := a + 1
   foo := a 	
end;


begin
	z := foo(6)
	m := z * 5
end.