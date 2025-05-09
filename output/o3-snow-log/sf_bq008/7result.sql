/*-----------------------------------------------------------
  January-2017 “Data Share” sessions that hit a “/home …” page
  • most_common_next_page  – page most often viewed after “/home…”
  • max_seconds_on_home    – longest time (seconds) spent on “/home…”
----------------------------------------------------------------*/
WITH jan_sessions AS (      -- explicit UNION ALL of all January-2017 tables
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170101" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170102" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170103" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170104" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170105" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170106" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170107" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170108" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170109" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170110" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170111" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170112" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170113" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170114" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170115" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170116" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170117" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170118" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170119" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170120" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170121" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170122" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170123" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170124" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170125" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170126" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170127" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170128" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170129" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170130" UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170131"
),
/* sessions whose campaign contains “data share” (case-insensitive) */
filtered_sessions AS (
    SELECT *
    FROM   jan_sessions
    WHERE  LOWER(PARSE_JSON("trafficSource"):"campaign"::STRING) LIKE '%data%share%'
),
/* explode the hits array */
flat_hits AS (
    SELECT  s."fullVisitorId"                        AS "fullVisitorId",
            s."visitId"                              AS "visitId",
            h.value:"hitNumber"::NUMBER              AS "hit_num",
            h.value:"time"::NUMBER                   AS "hit_time",
            h.value:"page":"pagePath"::STRING        AS "page_path"
    FROM   filtered_sessions  s,
           LATERAL FLATTEN(INPUT => PARSE_JSON(s."hits")) h
),
/* “/home…” hits and their following page */
home_sequence AS (
    SELECT  "fullVisitorId",
            "visitId",
            "page_path"                                                  AS "home_page",
            LEAD("page_path") OVER (PARTITION BY "fullVisitorId","visitId"
                                     ORDER BY "hit_num")                AS "next_page",
            LEAD("hit_time") OVER (PARTITION BY "fullVisitorId","visitId"
                                     ORDER BY "hit_num") - "hit_time"   AS "ms_to_next"
    FROM    flat_hits
    WHERE   "page_path" ILIKE '/home%'
),
/* most frequent next page (excluding NULL) */
common_next AS (
    SELECT  "next_page"
    FROM   (
        SELECT "next_page",
               COUNT(*)                              AS cnt,
               ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
        FROM   home_sequence
        WHERE  "next_page" IS NOT NULL
        GROUP  BY "next_page"
    )
    WHERE  rn = 1
),
/* maximum dwell time on “/home…” before navigating away */
max_time AS (
    SELECT  MAX("ms_to_next")/1000.0   AS "max_seconds_on_home"
    FROM    home_sequence
    WHERE   "next_page" IS NOT NULL
)
/* final answer */
SELECT  c."next_page"          AS "most_common_next_page",
        m."max_seconds_on_home"
FROM    common_next  c
CROSS   JOIN max_time m;