## in a separate test file
use Test::More;

use Test::Spelling;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
AnnoCPAN
BUILDARGS
eXtension
Jens
Rehsack
Inkster
