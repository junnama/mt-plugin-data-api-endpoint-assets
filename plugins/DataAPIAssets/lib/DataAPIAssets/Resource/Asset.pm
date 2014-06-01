package DataAPIAssets::Resource::Asset;
use strict;

sub image_width {
    my ( $asset, $hash, $field, $stash ) = @_;
    if ( $asset->class eq 'image' ) {
        return $asset->image_width;
    }
    return undef;
}

sub image_height {
    my ( $asset, $hash, $field, $stash ) = @_;
    if ( $asset->class eq 'image' ) {
        return $asset->image_height;
    }
    return undef;
}

1;