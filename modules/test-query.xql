xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://lasy.net/feinstaubsensor/config" at "config.xqm";
import module namespace http = "http://expath.org/ns/http-client";


let $feinstaub-data := collection($config:app-root || "/data/xml")//sample

let $url := "http://api.luftdaten.info/static/v1/sensor/2125/"
let $req := <http:request href="{$url}" method="get"/>
let $res := http:send-request($req)[2]
return 
    util:binary-to-string($res)
