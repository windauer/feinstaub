xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://lasy.net/feinstaubsensor/config" at "config.xqm";
import module namespace http = "http://expath.org/ns/http-client";


let $url := "http://api.luftdaten.info/static/v1/sensor/2125/"
let $req := <http:request href="{$url}" method="get"/>

let $http-response := http:send-request($req)
let $json-as-string := util:binary-to-string($http-response[2])
return 
    $json-as-string