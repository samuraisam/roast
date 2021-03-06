use v6;
use Test;

plan 2;

my $path = "io-handle-testfile";

##
# Test that we flush when we go out of scope
#?niecza skip "Unable to resolve method open in type IO"
{
    {
        my $fh = $path.IO.open(:w);
        $fh.print("42");
    }
    #?rakudo todo "doesn't flush"
    is slurp($path), "42", "buffer is flushed when IO goes out of scope";
}

#?rakudo todo "doesn't flush"
#?niecza skip "Unable to resolve method open in type IO"
{
    $path.IO.open(:w).print("24");
    is slurp($path), "24", "buffer is flushed when IO goes out of scope";
}

try { unlink $path }

CATCH {
    try { unlink $path; }
}

if $path.IO.e {
    say "Warn: '$path shouldn't exist";
    unlink $path;
}

done;
