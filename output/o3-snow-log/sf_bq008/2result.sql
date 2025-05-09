/*  Most–common “next page” after any ‘/home…’ view, and the longest dwell-time
    on that “/home” hit, for all January-2017 sessions whose campaign name
    contains the phrase “Data Share”.                                            */

WITH sessions_jan_2017 AS (   -- 1. union every January-2017 daily table
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170101"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170102"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170103"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170104"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170105"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170106"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170107"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170108"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170109"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170110"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170111"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170112"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170113"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170114"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170115"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170116"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170117"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170118"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170119"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170120"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170121"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170122"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170123"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170124"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170125"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170126"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170127"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170128"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170129"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170130"
    UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170131"
),
/* 2. keep only hits from those sessions whose campaign contains “Data Share”   */
filtered_hits AS (
    SELECT
        s."fullVisitorId",
        s."visitId",
        h.value:hitNumber::NUMBER     AS hit_num,
        h.value:time::NUMBER          AS hit_time_ms,
        h.value:page:pagePath::STRING AS page_path
    FROM sessions_jan_2017 s,
         LATERAL FLATTEN (INPUT => PARSE_JSON(s."hits")) h
    WHERE PARSE_JSON(s."trafficSource"):campaign::STRING ILIKE '%data%share%'
),
/* 3. add each hit’s subsequent page & timestamp                                 */
nav AS (
    SELECT
        "fullVisitorId",
        "visitId",
        hit_num,
        page_path,
        hit_time_ms,
        LEAD(page_path)   OVER (PARTITION BY "fullVisitorId","visitId" ORDER BY hit_num) AS next_page,
        LEAD(hit_time_ms) OVER (PARTITION BY "fullVisitorId","visitId" ORDER BY hit_num) AS next_hit_time_ms
    FROM filtered_hits
),
/* 4. restrict to hits whose *current* page starts with ‘/home’                  */
home_records AS (
    SELECT
        next_page,
        (next_hit_time_ms - hit_time_ms)/1000.0 AS seconds_on_home
    FROM nav
    WHERE page_path ILIKE '/home%' AND next_page IS NOT NULL
),
/* 5a. most–frequent next page                                                   */
most_common AS (
    SELECT next_page AS most_common_next_page
    FROM home_records
    GROUP BY next_page
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
/* 5b. longest dwell-time                                                        */
max_dwell AS (
    SELECT MAX(seconds_on_home) AS max_seconds_on_home
    FROM home_records
)
/* 6. final answer                                                               */
SELECT
    m.most_common_next_page,
    d.max_seconds_on_home
FROM most_common m
CROSS JOIN max_dwell d;