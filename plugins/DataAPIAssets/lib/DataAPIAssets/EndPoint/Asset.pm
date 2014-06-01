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
    my $iter = MT->model( $class )->load_iter( { blog_id => $blog->id } );
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