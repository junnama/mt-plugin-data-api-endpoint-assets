package DataAPIAssets::EndPoint::Asset;
use strict;

use MT::DataAPI::Endpoint::Common;

sub list_assets {
    my ( $app, $endpoint ) = @_;
    my ( $blog ) = context_objects( @_ ) or return;
    if ( MT->config( 'DataAPIAssetsRequiresLogin' ) ) {
        if (! $app->user || $app->user->is_anonymous
            || (! $app->can_do( 'access_to_insert_asset_list' ) ) ) {
            return $app->print_error( 'Unauthorized', 401 );
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
    my $iter = MT->model( $class )->load_iter( { blog_id => $blog->id }, $args );
    my @assets;
    while ( my $asset = $iter->() ) {
        push( @assets, $asset );
    }
    return {
        totalResults => scalar( @assets ),
        items => \@assets,
    };
}

1;