xquery version "3.1";

module namespace app="https://lasy.net/feinstaubsensor/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://lasy.net/feinstaubsensor/config" at "config.xqm";
import module namespace http = "http://expath.org/ns/http-client";

declare function app:init ($node as node(), $model as map(*)) {
    let $feinstaub-data := collection($config:app-root || "/data/sensor/3389190/")//sample
    let $samples := for $sample in $feinstaub-data
                        order by $sample/@timestamp descending
                            return $sample
    let $new-model := map:new (( $model, map:entry ( "samples", $samples ) ))
    return 
        templates:process($node/*, $new-model)
};



declare %templates:wrap function app:temperature ($node as node(), $model as map(*)) {
    $model?sample//temperature/text()
};

declare %templates:wrap function app:humidity ($node as node(), $model as map(*)) {
    $model?sample//humidity/text()
};

declare %templates:wrap function app:p1 ($node as node(), $model as map(*)) {
    $model?sample//P1/text()
};

declare %templates:wrap function app:p2 ($node as node(), $model as map(*)) {
    $model?sample//P2/text()
};

declare %templates:wrap function app:timestamp ($node as node(), $model as map(*)) {
    $model?sample/@timestamp/string()
};