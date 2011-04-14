use v6;

use Test;

plan 8;

# L<S06/Routine modifiers/>
# L<S06/Parameters and arguments/>

# Simple case.
{
    multi m1("foo") { 1 }
    multi m1("bar") { 2 }

    is m1("foo"), 1,       "literal Str in signature matches value correctly";
    is m1("bar"), 2,       "literal Str in signature matches value correctly";
    dies_ok { m1("baz") }, "dies if no matching value even if type matches";
}

# More complex case. Here we check that the multis get the right narrowness,
# based upon the type of the literal, and are narrower than a candidate of
# the same type because they have constraints.
{
    multi m2(1)      { "a" }
    multi m2(2)      { "b" }
    multi m2(Int $x) { "c" }   #OK not used
    multi m2($x)     { "d" }   #OK not used

    is m2(1),   "a", 'literal Int in signature matches value correctly';
    is m2(2),   "b", 'literal Int in signature matches value correctly';
    is m2(3),   "c", 'fallback to Int variant which is less narrow than constrained one';
    is m2("x"), "d", 'if not an Int at all, fall back to Any candidate';
}

# RT #88562
#?rakudo skip 'RT 88562'
{
    multi m3(0     ,     $       ) { 'a' };
    multi m3(Int $n, Str $a = 'A') { 'b' };

    is m3(2, 'A'), 'b', 'literal Int, anonymous parameters and default values mix';
}

# vim: ft=perl6
