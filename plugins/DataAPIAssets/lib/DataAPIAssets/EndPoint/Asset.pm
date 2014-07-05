package DataAPIAssets::EndPoint::Asset;
use strict;

use MT::DataAPI::Endpoint::Common;

sub data_api_pre_save_asset {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( my $asset = $app->param( 'asset' ) ) {
        $asset = MT::DataAPI::Format::JSON::unserialize( $asset );
        my $tags = $asset->{ tags };
        if (ref $tags ne 'ARRAY' ) {
            $obj->remove_tags;
        }
    }
    return 1;
}

sub get_asset {
    my ( $app, $endpoint ) = @_;
    my ( $blog, $asset ) = context_objects( @_ ) or return;
    if ( MT->config( 'DataAPIAssetsRequiresLogin' ) ) {
        if (! $app->user || $app->user->is_anonymous ) {
            return $app->print_error( 'Unauthorized', 401 );
        } elsif (! $app->can_do( 'access_to_insert_asset_list' ) ) {
            return $app->print_error( 'Permission denied.', 401 );
        }
    }
    return $asset;
}

sub update_asset {
    my ( $app, $endpoint ) = @_;
    my ( $blog, $asset ) = context_objects( @_ ) or return;
    if (! $app->user || $app->user->is_anonymous ) {
        return $app->print_error( 'Unauthorized', 401 );
    } elsif (! $app->can_do( 'edit_assets' ) ) {
        return $app->print_error( 'Permission denied.', 401 );
    }
    if ( my $method = $app->param( '__method' ) ) {
        if ( lc( $method ) eq 'delete' ) {
            return delete_asset( @_ );
        }
    }
    my ( $fh, $info ) = $app->upload_info( 'file' );
    my $new_obj;
    if ( $fh && (! $app->param( 'asset' ) ) ) {
        $new_obj = $asset;
    } else {
        $new_obj = $app->resource_object( 'asset', $asset ) or return;
    }
    my ( $tmp_id, $tmp_file );
    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    if ( $fh ) {
        return $app->error( 403 ) unless $app->can_do( 'upload' );
        $tmp_file = $asset->file_path;
        if ( $fmgr->exists( $tmp_file ) ) {
            $fmgr->rename( $tmp_file, "${tmp_file}.tmp" );
        }
        $app->param( 'site_path', 1 );
        my %keys =( overwrite => 'overwrite_yes',
                    fileName => 'fname',
                    temp => 'temp',
                    path => 'extra_path',
                    autoRenameIfExists => 'auto_rename_if_exists',
                    normalizeOrientation => 'normalize_orientation',
                  );
        for my $key ( keys %keys ) {
            if ( my $value = $app->param( $key ) ) {
                $app->param( $keys{ $key }, $value );
            }
        }
        require MT::CMS::Asset;
        my ( $upload_asset, $bytes ) = MT::CMS::Asset::_upload_file( $app, @_ );
        if (! $upload_asset ) {
            $fmgr->rename( "${tmp_file}.tmp", $tmp_file );
            return $app->error( 500 );
        } else {
            $tmp_id = $upload_asset->id;
            $upload_asset->clear_cache();
            $upload_asset->clear_cache();
            $new_obj = MT->model( $upload_asset->class )->new;
            my $cols = $asset->column_names;
            my @not_cp = qw( file_path mime_type url class image_width image_height );
            for my $col ( @$cols ) {
                if ( $new_obj->has_column( $col ) ) {
                    if (! grep( /^$col$/, @not_cp ) ) {
                        $new_obj->$col( $asset->$col );
                    } else {
                        $new_obj->$col( $upload_asset->$col );
                    }
                }
            }
            if ( $upload_asset->class eq 'image' ) {
                $new_obj->image_width( $upload_asset->image_width );
                $new_obj->image_height( $upload_asset->image_height );
            }
            $new_obj->clear_cache();
            $new_obj->id( $asset->id );
            $new_obj->save or return $app->error( 500 );
            if ( $app->param( 'asset' ) ) {
                $new_obj = $app->resource_object( 'asset', $new_obj ) or return;
            }
        }
    }
    $asset->clear_cache();
    $new_obj->clear_cache();
    my @tl = MT::Util::offset_time_list( time, $blog );
    my $ts = sprintf '%04d%02d%02d%02d%02d%02d', $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
    save_object(
        $app, 'asset',
        $new_obj,
        $asset,
        sub {
            $new_obj->id( $asset->id );
            $new_obj->modified_on( $ts );
            $new_obj->modified_by( $app->user->id );
            $_[ 0 ]->();
        }
    ) or return;
    if ( $tmp_id ) {
        my $new_file = $new_obj->file_path;
        if ( $fmgr->exists( $new_file ) ) {
            $fmgr->rename( $new_file, "${new_file}.tmp" );
        }
        if ( $tmp_id != $new_obj->id ) {
            if ( my $upload = MT->model( 'asset' )->load( $tmp_id ) ) {
                $upload->remove or return $app->error( 500 );
            }
        }
        if ( $fmgr->exists( "${new_file}.tmp" ) ) {
            $fmgr->rename( "${new_file}.tmp", $new_file );
        }
        if ( $fmgr->exists( "${tmp_file}.tmp" ) ) {
            $fmgr->delete( "${tmp_file}.tmp" );
        }
    }
    $new_obj->clear_cache();
    return $new_obj;
}

sub delete_asset {
    my ( $app, $endpoint ) = @_;
    my ( $blog, $asset ) = context_objects( @_ ) or return;
    if (! $app->user || $app->user->is_anonymous ) {
        return $app->print_error( 'Unauthorized', 401 );
    } elsif (! $app->can_do( 'edit_assets' ) ) {
        return $app->print_error( 'Permission denied.', 401 );
    }
    remove_object( $app, 'asset', $asset ) or return;
    return $asset;
}

sub _list_assets {
    my ( $app, $endpoint ) = @_;
    my ( $blog ) = context_objects( @_ ) or return;
    if ( MT->config( 'DataAPIAssetsRequiresLogin' ) ) {
        if (! $app->user || $app->user->is_anonymous ) {
            return $app->print_error( 'Unauthorized', 401 );
        } elsif (! $app->can_do( 'access_to_insert_asset_list' ) ) {
            return $app->print_error( 'Permission denied.', 401 );
        }
    }
    my $route = $endpoint->{ route };
    my @paths = split( /\//, $route );
    my $class = $paths[ scalar( @paths ) - 1 ];
    $class =~ s/s$//;
    run_permission_filter( $app, 'data_api_list_permission_filter', 'asset' ) or return;
    # sortBy ( created_on | modified_on | id | label )
    # sortOrder ( descend | ascend )
    # limit offset
    my $args;
    my $sort_order = 'descend';
    my $sort_by = 'modified_on';
    my @sort_col = qw( created_on modified_on id label );
    if ( my $sortBy = $app->param( 'sortBy' ) ) {
        if ( grep( /^$sortBy$/, @sort_col ) ) {
            $sort_by = $sortBy;
        }
    }
    if ( my $sortOrder = $app->param( 'sortOrder' ) ) {
        if ( $sortOrder eq 'ascend' ) {
            $sort_order = $sortOrder;
        }
    }
    $args->{ sort } = $sort_by;
    $args->{ direction } = $sort_order;
    my $limit = 10;
    if ( $app->param( 'limit' ) ) {
        $limit = $app->param( 'limit' ) + 0;
    }
    my $offset = 0;
    if ( $app->param( 'offset' ) ) {
        $offset = $app->param( 'offset' ) + 0;
    }
    $args->{ limit } = $limit;
    $args->{ offset } = $offset;
    my $terms = { blog_id => $blog->id };
    my $count = 0;
    my @assets = [];
    if ( my $search = $app->param( 'search' ) ) {
        $search = MT::Util::trim( $search );
        # searchFields label,description,file_name
        my $searchFields = $app->param( 'searchFields' ) || 'label,description,file_name';
        my @fields = split( /,/, $searchFields );
        my @queries = [ $terms, '-and' ];
        my $i = 0;
        for my $field( @fields ) {
            $field = MT::Util::trim( $field );
            push( @queries, { $field => { like => '%' . $search . '%' } } );
            $i++;
            if ( $i != scalar( @fields ) ) {
                push( @queries, '-or' );
            }
            $terms->{ $field } = { like => '%' . $search . '%' };
        }
        $count = MT->model( $class )->count( \@queries );
        @assets = MT->model( $class )->load( \@queries, $args );
    } else {
        $count = MT->model( $class )->count( $terms );
        @assets = MT->model( $class )->load( $terms, $args );
    }
    return {
        totalResults => $count + 0,
        items => \@assets,
    };
}

1;