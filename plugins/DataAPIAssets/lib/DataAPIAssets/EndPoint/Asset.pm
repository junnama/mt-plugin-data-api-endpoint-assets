package DataAPIAssets::EndPoint::Asset;
use strict;

use MT::DataAPI::Endpoint::Common;

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
    my $tmp_id;
    if ( $fh ) {
        return $app->error( 403 ) unless $app->can_do( 'upload' );
        my $tmp_file = $asset->file_path;
        require MT::FileMgr;
        my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
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
        my ( $upload_asset, $bytes ) = MT::CMS::Asset::_upload_file( $app, @_ );
        if (! $upload_asset ) {
            $fmgr->rename( "${tmp_file}.tmp", $tmp_file );
            return $app->error( 500 );
        } else {
            $fmgr->delete( "${tmp_file}.tmp" );
            $tmp_id = $upload_asset->id;
            $upload_asset->id( $asset->id );
            $upload_asset->clear_cache();
            if ( $app->param( 'asset' ) ) {
                $new_obj = $app->resource_object( 'asset', $upload_asset ) or return;
            } else {
                $new_obj = $upload_asset;
                my $cols = $asset->column_names;
                my @not_cp = qw( file_path mime_type url class );
                for my $col ( @$cols ) {
                    if (! grep( /^$col$/, @not_cp ) ) {
                        if ( $new_obj->has_column( $col ) ) {
                            $new_obj->$col( $asset->$col );
                        }
                    }
                }
            }
            $new_obj->clear_cache();
        }
    }
    save_object(
        $app, 'asset',
        $new_obj,
        $asset,
        sub {
            $new_obj->modified_by( $app->user->id );
            $_[ 0 ]->();
        }
    ) or return;
    if ( $tmp_id ) {
        if ( my $upload = MT->model( 'asset' )->load( $tmp_id ) ) {
            $upload->remove or return $app->error( 500 );
        }
    }
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

sub list_assets {
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
    my $sort_by = 'id';
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
    $args->{ sort_by } = $sort_by;
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
    my $count = MT->model( $class )->count( $terms );
    my @assets = MT->model( $class )->load( $terms, $args );
    return {
        totalResults => $count + 0,
        items => \@assets,
    };
}

1;