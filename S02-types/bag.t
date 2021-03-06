use v6;
use Test;

plan 137;

sub showkv($x) {
    $x.keys.sort.map({ $^k ~ ':' ~ $x{$k} }).join(' ')
}

# L<S02/Immutable types/'the bag listop'>

{
    my $b = bag <a foo a a a a b foo>;
    isa_ok $b, Bag, '&bag produces a Bag';
    is showkv($b), 'a:5 b:1 foo:2', '...with the right elements';

    is $b.default, 0, "Defaults to 0";
    is $b<a>, 5, 'Single-key subscript (existing element)';
    isa_ok $b<a>, Int, 'Single-key subscript yields an Int';
    is $b<santa>, 0, 'Single-key subscript (nonexistent element)';
    isa_ok $b<santa>, Int, 'Single-key subscript yields an Int (nonexistent element)';
    ok $b.exists('a'), '.exists with existing element';
    nok $b.exists('santa'), '.exists with nonexistent element';

    is $b.values.elems, 3, "Values returns the correct number of values";
    is ([+] $b.values), 8, "Values returns the correct sum";
    ok ?$b, "Bool returns True if there is something in the Bag";
    nok ?Bag.new(), "Bool returns False if there is nothing in the Bag";

    my $hash;
    lives_ok { $hash = $b.hash }, ".hash doesn't die";
    isa_ok $hash, Hash, "...and it returned a Hash";
    is showkv($hash), 'a:5 b:1 foo:2', '...with the right elements';

    dies_ok { $b<a> = 5 }, "Can't assign to an element (Bags are immutable)";
    dies_ok { $b<a>++ }, "Can't increment an element (Bags are immutable)";
    dies_ok { $b.keys = <c d> }, "Can't assign to .keys";
    dies_ok { $b.values = 3, 4 }, "Can't assign to .values";

    is ~$b<a b>, "5 1", 'Multiple-element access';
    is ~$b<a santa b easterbunny>, "5 0 1 0", 'Multiple-element access (with nonexistent elements)';

    is $b.elems, 8, '.elems gives sum of values';
    is +$b, 8, '+$bag gives sum of values';
}

#?rakudo skip "Bag.ACCEPTS NYI"
{
    ok (bag <a b c>) ~~ (bag <a b c>), "Identical bags smartmatch with each other";
    ok (bag <a b c c>) ~~ (bag <a b c c>), "Identical bags smartmatch with each other";
    nok (bag <b c>) ~~ (bag <a b c>), "Subset does not smartmatch";
    nok (bag <a b c>) ~~ (bag <a b c c>), "Subset (only quantity different) does not smartmatch";
    nok (bag <a b c d>) ~~ (bag <a b c>), "Superset does not smartmatch";
    nok (bag <a b c c c>) ~~ (bag <a b c c>), "Superset (only quantity different) does not smartmatch";
    nok "a" ~~ (bag <a b c>), "Smartmatch is not element of";
    ok (bag <a b c>) ~~ Bag, "Type-checking smartmatch works";

    ok (set <a b c>) ~~ (bag <a b c>), "Set smartmatches with equivalent bag";
    nok (set <a a a b c>) ~~ (bag <a a a b c>), "... but not if the Bag has greater quantities";
    nok (set <a b c>) ~~ Bag, "Type-checking smartmatch works";
}

#?rakudo skip ".Set NYI"
{
    isa_ok "a".Bag, Bag, "Str.Bag makes a Bag";
    is showkv("a".Bag), 'a:1', "'a'.Bag is bag a";

    isa_ok (a => 100000).Bag, Bag, "Pair.Bag makes a Bag";
    is showkv((a => 100000).Bag), 'a:100000', "(a => 100000).Bag is bag a:100000";
    is showkv((a => 0).Bag), '', "(a => 0).Bag is the empty bag";

    isa_ok <a b c>.Bag, Bag, "<a b c>.Bag makes a Bag";
    is showkv(<a b c a>.Bag), 'a:2 b:1 c:1', "<a b c a>.Bag makes the bag a:2 b:1 c:1";
    is showkv(["a", "b", "c", "a"].Bag), 'a:2 b:1 c:1', "[a b c a].Bag makes the bag a:2 b:1 c:1";
    is showkv([a => 3, b => 0, 'c', 'a'].Bag), 'a:4 c:1', "[a => 3, b => 0, 'c', 'a'].Bag makes the bag a:4 c:1";

    isa_ok {a => 2, b => 4, c => 0}.Bag, Bag, "{a => 2, b => 4, c => 0}.Bag makes a Bag";
    is showkv({a => 2, b => 4, c => 0}.Bag), 'a:2 b:4', "{a => 2, b => 4, c => 0}.Bag makes the bag a:2 b:4";
}

{
    my $s = bag <a a b foo>;
    is $s<a>:exists, True, ':exists with existing element';
    is $s<santa>:exists, False, ':exists with nonexistent element';
    dies_ok { $s<a>:delete }, ':delete does not work on bag';
}

{
    my $b = bag 'a', False, 2, 'a', False, False;
    my @ks = $b.keys;
    #?niecza 2 todo
    #?rakudo 2 todo ''
    is @ks.grep(Int)[0], 2, 'Int keys are left as Ints';
    is @ks.grep(* eqv False).elems, 1, 'Bool keys are left as Bools';
    is @ks.grep(Str)[0], 'a', 'And Str keys are permitted in the same set';
    is $b{2, 'a', False}.sort.join(' '), '1 2 3', 'All keys have the right values';
}

#?niecza skip "Unmatched key in Hash.LISTSTORE"
{
    my %h = bag <a b o p a p o o>;
    ok %h ~~ Hash, 'A hash to which a Bag has been assigned remains a hash';
    is showkv(%h), 'a:2 b:1 o:3 p:2', '...with the right elements';
}

{
    my $b = bag <a b o p a p o o>;
    isa_ok $b, Bag, '&Bag.new given an array of strings produces a Bag';
    is showkv($b), 'a:2 b:1 o:3 p:2', '...with the right elements';
}

{
    my $b = bag [ foo => 10, bar => 17, baz => 42, santa => 0 ];
    isa_ok $b, Bag, '&Bag.new given an array of pairs produces a Bag';
    #?rakudo todo "New bag constructor NYI"
    is +$b, 1, "... with one element";
}

{
    my $b = bag { foo => 10, bar => 17, baz => 42, santa => 0 }.hash;
    isa_ok $b, Bag, '&Bag.new given a Hash produces a Bag';
    #?rakudo todo "Old implementation used values as bag counts"
    is +$b, 4, "... with four elements";
    #?niecza todo "Non-string bag elements NYI"
    #?rakudo todo "Old implementation used values as bag counts"
    is +$b.grep(Pair), 4, "... which are all Pairs";
}

{
    my $b = bag { foo => 10, bar => 17, baz => 42, santa => 0 };
    isa_ok $b, Bag, '&Bag.new given a Hash produces a Bag';
    #?rakudo todo "New bag constructor NYI"
    is +$b, 1, "... with one element";
}

{
    my $b = bag set <foo bar foo bar baz foo>;
    isa_ok $b, Bag, '&Bag.new given a Set produces a Bag';
    #?rakudo todo "New bag constructor NYI"
    is +$b, 1, "... with one element";
}

{
    my $b = bag KeySet.new(<foo bar foo bar baz foo>);
    isa_ok $b, Bag, '&Bag.new given a KeySet produces a Bag';
    #?rakudo todo "New bag constructor NYI"
    is +$b, 1, "... with one element";
}

{
    my $b = bag KeyBag.new(<foo bar foo bar baz foo>);
    isa_ok $b, Bag, '&Bag.new given a KeyBag produces a Bag';
    #?rakudo todo "New bag constructor NYI"
    is +$b, 1, "... with one element";
}

{
    my $b = bag set <foo bar foo bar baz foo>;
    isa_ok $b, Bag, '&bag given a Set produces a Bag';
    #?rakudo todo "New bag constructor NYI"
    is +$b, 1, "... with one element";
}

# L<S02/Names and Variables/'C<%x> may be bound to'>

{
    my %b := bag <a b c b>;
    isa_ok %b, Bag, 'A Bag bound to a %var is a Bag';
    is showkv(%b), 'a:1 b:2 c:1', '...with the right elements';

    is %b<b>, 2, 'Single-key subscript (existing element)';
    is %b<santa>, 0, 'Single-key subscript (nonexistent element)';

    dies_ok { %b<a> = 1 }, "Can't assign to an element (Bags are immutable)";
    dies_ok { %b = bag <a b> }, "Can't assign to a %var implemented by Bag";
}

#?rakudo skip ".Bag NYI"
{
    my $b = { foo => 10, bar => 1, baz => 2}.Bag;

    # .list is just the keys, as per TimToady: 
    # http://irclog.perlgeek.de/perl6/2012-02-07#i_5112706
    isa_ok $b.list.elems, 3, ".list returns 3 things";
    is $b.list.grep(Str).elems, 3, "... all of which are Str";

    isa_ok $b.pairs.elems, 3, ".pairs returns 3 things";
    is $b.pairs.grep(Pair).elems, 3, "... all of which are Pairs";
    is $b.pairs.grep({ .key ~~ Str }).elems, 3, "... the keys of which are Strs";
    is $b.pairs.grep({ .value ~~ Int }).elems, 3, "... and the values of which are Ints";

    is $b.iterator.grep(Pair).elems, 3, ".iterator yields three Pairs";
    is $b.iterator.grep({ .key ~~ Str }).elems, 3, "... the keys of which are Strs";
    is $b.iterator.grep({True}).elems, 3, "... and nothing else";
}

#?rakudo skip ".Bag NYI"
{
    my $b = { foo => 10000000000, bar => 17, baz => 42 }.Bag;
    my $s;
    my $c;
    lives_ok { $s = $b.perl }, ".perl lives";
    isa_ok $s, Str, "... and produces a string";
    ok $s.chars < 1000, "... of reasonable length";
    lives_ok { $c = eval $s }, ".perl.eval lives";
    isa_ok $c, Bag, "... and produces a Bag";
    is showkv($c), showkv($b), "... and it has the correct values";
}

#?rakudo skip ".Bag NYI"
{
    my $b = { foo => 2, bar => 3, baz => 1 }.Bag;
    my $s;
    lives_ok { $s = $b.Str }, ".Str lives";
    isa_ok $s, Str, "... and produces a string";
    #?rakudo todo 'Bag stringification'
    is $s.split(" ").sort.join(" "), "bar bar bar baz foo foo", "... which only contains bar baz and foo with the proper counts and separated by spaces";
}

#?rakudo skip ".Bag NYI"
{
    my $b = { foo => 10000000000, bar => 17, baz => 42 }.Bag;
    my $s;
    lives_ok { $s = $b.gist }, ".gist lives";
    isa_ok $s, Str, "... and produces a string";
    ok $s.chars < 1000, "... of reasonable length";
    ok $s ~~ /foo/, "... which mentions foo";
    ok $s ~~ /bar/, "... which mentions bar";
    ok $s ~~ /baz/, "... which mentions baz";
}

# L<S02/Names and Variables/'C<%x> may be bound to'>

{
    my %b := bag "a", "b", "c", "b";
    isa_ok %b, Bag, 'A Bag bound to a %var is a Bag';
    is showkv(%b), 'a:1 b:2 c:1', '...with the right elements';

    is %b<b>, 2, 'Single-key subscript (existing element)';
    is %b<santa>, 0, 'Single-key subscript (nonexistent element)';
}

# L<S32::Containers/Bag/roll>

{
    my $b = Bag.new("a", "b", "b");

    my $a = $b.roll;
    ok $a eq "a" || $a eq "b", "We got one of the two choices";

    my @a = $b.roll(2);
    is +@a, 2, '.roll(2) returns the right number of items';
    is @a.grep(* eq 'a').elems + @a.grep(* eq 'b').elems, 2, '.roll(2) returned "a"s and "b"s';

    @a = $b.roll: 100;
    is +@a, 100, '.roll(100) returns 100 items';
    ok 2 < @a.grep(* eq 'a') < 75, '.roll(100) (1)';
    ok @a.grep(* eq 'a') + 2 < @a.grep(* eq 'b'), '.roll(100) (2)';
}

#?rakudo skip ".Bag NYI"
{
    my $b = {"a" => 100000000000, "b" => 1}.Bag;

    my $a = $b.roll;
    ok $a eq "a" || $a eq "b", "We got one of the two choices (and this was pretty quick, we hope!)";

    my @a = $b.roll: 100;
    is +@a, 100, '.roll(100) returns 100 items';
    ok @a.grep(* eq 'a') > 97, '.roll(100) (1)';
    ok @a.grep(* eq 'b') < 3, '.roll(100) (2)';
}

# L<S32::Containers/Bag/pick>

{
    my $b = Bag.new("a", "b", "b");

    my $a = $b.pick;
    ok $a eq "a" || $a eq "b", "We got one of the two choices";

    my @a = $b.pick(2);
    is +@a, 2, '.pick(2) returns the right number of items';
    ok @a.grep(* eq 'a').elems <= 1, '.pick(2) returned at most one "a"';
    is @a.grep(* eq 'b').elems, 2 - @a.grep(* eq 'a').elems, '.pick(2) and the rest are "b"';

    @a = $b.pick: *;
    is +@a, 3, '.pick(*) returns the right number of items';
    is @a.grep(* eq 'a').elems, 1, '.pick(*) (1)';
    is @a.grep(* eq 'b').elems, 2, '.pick(*) (2)';
}

#?rakudo skip ".Bag NYI"
{
    my $b = {"a" => 100000000000, "b" => 1}.Bag;

    my $a = $b.pick;
    ok $a eq "a" || $a eq "b", "We got one of the two choices (and this was pretty quick, we hope!)";

    my @a = $b.pick: 100;
    is +@a, 100, '.pick(100) returns 100 items';
    ok @a.grep(* eq 'a') > 98, '.pick(100) (1)';
    ok @a.grep(* eq 'b') < 2, '.pick(100) (2)';
}

#?rakudo skip ".Bag NYI"
{
    isa_ok 42.Bag, Bag, "Method .Bag works on Int-1";
    is showkv(42.Bag), "42:1", "Method .Bag works on Int-2";
    isa_ok "blue".Bag, Bag, "Method .Bag works on Str-1";
    is showkv("blue".Bag), "blue:1", "Method .Bag works on Str-2";
    my @a = <Now the cross-handed set was the Paradise way>;
    isa_ok @a.Bag, Bag, "Method .Bag works on Array-1";
    is showkv(@a.Bag), "Now:1 Paradise:1 cross-handed:1 set:1 the:2 was:1 way:1", "Method .Bag works on Array-2";
    my %x = "a" => 1, "b" => 2;
    isa_ok %x.Bag, Bag, "Method .Bag works on Hash-1";
    is showkv(%x.Bag), "a:1 b:2", "Method .Bag works on Hash-2";
    isa_ok (@a, %x).Bag, Bag, "Method .Bag works on Parcel-1";
    is showkv((@a, %x).Bag), "Now:1 Paradise:1 a:1 b:2 cross-handed:1 set:1 the:2 was:1 way:1",
       "Method .Bag works on Parcel-2";
}

# vim: ft=perl6
