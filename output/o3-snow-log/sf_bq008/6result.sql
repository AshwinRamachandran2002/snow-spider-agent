/*  January-2017 : “Data Share” sessions that touched any “/home” page
    – find the page visited NEXT most often
    – and the maximum seconds spent on “/home” before leaving            */

WITH january AS (                       -- all 31 daily tables for Jan-2017
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170101 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170102 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170103 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170104 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170105 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170106 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170107 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170108 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170109 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170110 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170111 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170112 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170113 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170114 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170115 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170116 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170117 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170118 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170119 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170120 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170121 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170122 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170123 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170124 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170125 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170126 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170127 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170128 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170129 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170130 UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170131
),
-- explode hit-level data for “Data Share” sessions
hits AS (
    SELECT  j."fullVisitorId",
            j."visitId",
            h.value:"hitNumber"::NUMBER               AS hit_num,
            h.value:"time"::NUMBER                    AS hit_time,
            h.value:"page":"pagePath"::STRING         AS page_path
    FROM    january j,
            LATERAL FLATTEN(input => j."hits") h
    WHERE   j."trafficSource":"campaign"::STRING ILIKE '%data%share%'
),
-- first "/home" hit per session
first_home AS (
    SELECT  "fullVisitorId",
            "visitId",
            MIN(hit_num)  AS home_hit_num,
            MIN(hit_time) AS home_hit_time
    FROM    hits
    WHERE   page_path ILIKE '/home%'
    GROUP BY 1,2
),
-- first hit AFTER the "/home" page
next_hit AS (
    SELECT  fh."fullVisitorId",
            fh."visitId",
            h.page_path                                 AS next_page,
            (h.hit_time - fh.home_hit_time) / 1000      AS seconds_on_home,
            ROW_NUMBER() OVER (
                PARTITION BY fh."fullVisitorId", fh."visitId"
                ORDER BY h.hit_num
            )                                           AS rn
    FROM    first_home fh
    JOIN    hits h
          ON fh."fullVisitorId" = h."fullVisitorId"
         AND fh."visitId"       = h."visitId"
    WHERE   h.hit_num > fh.home_hit_num
),
-- one record per session: the immediate next page + dwell time
per_session AS (
    SELECT  next_page,
            seconds_on_home
    FROM    next_hit
    WHERE   rn = 1
)
-- final answer: most-common next page & max dwell time
SELECT  next_page                              AS most_common_next_page,
        COUNT(*)                               AS session_count,
        MAX(seconds_on_home)                   AS max_seconds_on_home
FROM    per_session
GROUP BY next_page
ORDER BY session_count DESC NULLS LAST
LIMIT 1;