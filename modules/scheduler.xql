xquery version "3.1";

import module namespace config="https://lasy.net/feinstaubsensor/config" at "config.xqm";
import module namespace scheduler="http://exist-db.org/xquery/scheduler" at "java:org.exist.xquery.modules.scheduler.SchedulerModule";

declare namespace sc="http://exist-db.org/xquery/scheduler";

declare variable $local:job-name := "scrape-luftdaten";
declare variable $local:cron := "0 */1 * * * ? *";

declare function local:start-job() {
    scheduler:schedule-xquery-cron-job($config:app-root || "/modules/cronjob.xql", $local:cron, $local:job-name)
};
  
declare function local:show-job() {
    let $jobs := scheduler:get-scheduled-jobs()
     return 
         $jobs//sc:job[@name=$local:job-name]     
};

declare function local:stop-job() {
    scheduler:delete-scheduled-job($local:job-name)
};

(: 
local:stop-job()
local:start-job()
local:show-job()
:)
<result>
    {local:show-job()}
</result>
