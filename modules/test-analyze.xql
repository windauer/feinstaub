xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://lasy.net/feinstaubsensor/config" at "config.xqm";
import module namespace http = "http://expath.org/ns/http-client";

let $raw-samples := collection($config:app-root || "/data/xml")//sample

return
    for $timestamp in distinct-values($raw-samples/@timestamp)          
            let $samples := $raw-samples[@timestamp = $timestamp]
            let $sensor-id := $samples[1]/@sensor-id/string()
            let $timestamp := $samples[1]/@timestamp/string()
            let $location-id := $samples[1]/location/@id/string()
            let $location-lat := $samples[1]/location/@latitude/string()
            let $location-long := $samples[1]/location/@longitude/string()
            let $location-country := $samples[1]/location/@country/string()
            
            return
                <sample timestamp="{$timestamp}" 
                        location-id="{$location-id}" latitude="{$location-lat}" 
                        longitude="{$location-long}" country="{$location-country}">
                        
                    <sensor id="{$samples[1]/sensor/@id/string()}" 
                            sample-id="{$samples[1]/@id/string()}" 
                            pin="{$samples[1]/sensor/@pin/string()}">
                        {   
                            $samples[1]/sensor/type, 
                            $samples[1]/P1,
                            $samples[1]/P2,
                            $samples[1]/temperature,
                            $samples[1]/humidity
                        }
                    </sensor>
                    <sensor id="{$samples[2]/sensor/@id/string()}" 
                            sample-id="{$samples[2]/@id/string()}" 
                            pin="{$samples[2]/sensor/@pin/string()}">
                        {   
                            $samples[2]/sensor/type, 
                            $samples[2]/P1,
                            $samples[2]/P2,
                            $samples[2]/temperature,
                            $samples[2]/humidity
                        }
                    </sensor>                            
                </sample>
