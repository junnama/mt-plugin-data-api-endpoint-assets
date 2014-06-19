mt-plugin-data-api-endpoint-assets
==================================

Add Movable Type's Data API Endpoints and Resources for MT::Asset Object\.

### Assets: list

Authorization is required If you specified DataAPIAssetsRequiresLogin 1 in mt\-config\.cgi

This method accepts GET only\.

    GET https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets
    GET https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets/image
    GET https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets/video
    GET https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets/audio

#### Response

* totalResults : The total number of assets found that by the requesst\.
* items : An array of assets resource\.

### Assets: get

Authorization is required If you specified DataAPIAssetsRequiresLogin 1 in mt\-config\.cgi

This method accepts GET only\.

    GET https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets/{asset_id}

### Assets: update

Authorization is required

This method accepts POST only\.

    POST https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets/{asset_id}

#### Request Body

* asset : An Asset resource for update\(JSON\)\(optional\)\.
* file: file data to overwrite\(optional\)\.

### Assets: delete

Authorization is required

This method accepts DELETE and POST with \_\_method=DELETE\.

    DELETE https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets/{asset_id}

### Additional Resources

See <a href="https://github.com/movabletype/Documentation/wiki/data-api-resource-assets" target="_blank">https://github.com/movabletype/Documentation/wiki/data-api-resource-assets</a>

* icon\_url : Icon's URL or Thumbnail URL\(string\)\.
* image_width : Width of Image file\(integer\)\.
* image_height : Height of Image file\(integer\)\.
