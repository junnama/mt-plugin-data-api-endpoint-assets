package DataAPIAssets::Resource::Asset;
use strict;

sub image_width {
    my ( $obj, $hash, $field, $stash ) = @_;
    if ( $obj->class eq 'image' ) {
        return $obj->image_width;
    }
    return undef;
}

sub image_height {
    my ( $obj, $hash, $field, $stash ) = @_;
    if ( $obj->class eq 'image' ) {
        return $obj->image_height;
    }
    return undef;
}

sub icon_url {
    my ( $obj, $hash, $field, $stash ) = @_;
    my $class_type = $obj->class;
    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new('Local');
    my $file_path = $obj->file_path;
    my $thumb_size = 45;
    my $img = MT->static_path . 'images/asset/' . $class_type . '-45.png';
    if ( $file_path && $fmgr->exists( $file_path ) ) {
        if ( $obj->has_thumbnail && $obj->can_create_thumbnail ) {
            my ( $orig_width, $orig_height )
                = ( $obj->image_width, $obj->image_height );
            my ( $thumbnail_url, $thumbnail_width, $thumbnail_height );
            if ( $orig_width > $thumb_size && $orig_height > $thumb_size ) {
                ( $thumbnail_url, $thumbnail_width, $thumbnail_height ) =
                    $obj->thumbnail_url(
                        Height => $thumb_size,
                        Width  => $thumb_size,
                        Square => 1
                        );
            } elsif ( $orig_width > $thumb_size ) {
                ( $thumbnail_url, $thumbnail_width, $thumbnail_height ) =
                    $obj->thumbnail_url(
                        Width => $thumb_size, );
            } elsif ( $orig_height > $thumb_size ) {
                ( $thumbnail_url, $thumbnail_width, $thumbnail_height ) =
                    $obj->thumbnail_url(
                        Height => $thumb_size, );
            } else {
                ( $thumbnail_url, $thumbnail_width, $thumbnail_height ) = 
                    ( $obj->url, $orig_width, $orig_height );
            }
            my $thumbnail_width_offset = int( ( $thumb_size - $thumbnail_width ) / 2 );
            my $thumbnail_height_offset = int( ( $thumb_size - $thumbnail_height ) / 2 );
            return $thumbnail_url if $thumbnail_url;
        }
    } else {
        $img = MT->static_path . 'images/asset/' . $class_type . '-warning-45.png';
    }
    return $img;
}

1;