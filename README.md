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

#### Query Parameters

* __search\(string\)__ : This is an optional parameter\. Search query\.
* __searchFields\(string\)__ : This is an optional parameter\. The comma separated field name list to search\. Default is 'label,description,file\_name'
* __limit\(unsigned integer\)__ : This is an optional parameter\. Maximum number of assets to retrieve. Default is 10\.
* offset\(unsigned integer\) : This is an optional parameter\. 0\-indexed offset\. Default is 0\.
* __sortBy\(string\)__ : This is an optional parameter\(Default: modified\_on\)\.
* __sortOrder\(string\)__ : This is an optional parameter\(Default: descend\)\.

#### Response

* totalResults : The total number of assets found that by the requesst\.
* items : An array of assets resource\.

### Assets: get

Authorization is required If you specified DataAPIAssetsRequiresLogin 1 in mt\-config\.cgi

This method accepts GET only\.

    GET https://your-host/your-mt-api.cgi/v1/sites/{blog_id}/assets/{asset_id}

### Assets: update

Authorization is required

This method accepts PUT and POST with \_\_method=PUT\.

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
