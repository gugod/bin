use v5.14;

package Brain::Helpers {
    use Moose ();
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        as_is => [ 'sha1_hex' ]
    );

    use Digest::SHA1 ();
    use Encode ();

    sub sha1_hex($) {
        my ($x) = @_;
        $x = Encode::encode_utf8($x) if Encode::is_utf8($x);
        return Digest::SHA1::sha1_hex($x);
    }
};

1;
