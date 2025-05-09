/*--------------------------------------------------------------
   In-January-2017  “Data Share” sessions that hit any “/home…”
   1. most frequently visited NEXT page after the “/home…” hit
   2. maximum time (secs) spent on that “/home…” hit before moving on
--------------------------------------------------------------*/
WITH january_sessions AS (          -- every daily table in Jan-2017
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
home_hits AS (                     -- every “/home…” page hit in those sessions
    SELECT
        t."fullVisitorId",
        t."visitId",
        h.value:"hitNumber"::INTEGER                                     AS hit_num,
        h.value:"time"::INTEGER                                         AS hit_time,
        h.value:"page":"pagePath"::STRING                               AS page_path,
        LEAD(h.value:"page":"pagePath"::STRING)  OVER(partition by t."fullVisitorId", t."visitId" 
                                                     order by h.value:"hitNumber"::INTEGER) AS next_page,
        LEAD(h.value:"time"::INTEGER)          OVER(partition by t."fullVisitorId", t."visitId" 
                                                     order by h.value:"hitNumber"::INTEGER)
        - h.value:"time"::INTEGER                                       AS time_spent_secs
    FROM january_sessions t,
         LATERAL FLATTEN(input => t."hits") h
    WHERE t."trafficSource":"campaign"::STRING ILIKE '%Data%Share%'      -- “Data Share” campaign
      AND h.value:"type"::STRING = 'PAGE'                                -- page hits only
      AND h.value:"page":"pagePath"::STRING ILIKE '/home%'               -- “/home…” pages
)
SELECT
    /* most-frequent next page (ignore nulls) */
    ( SELECT next_page
      FROM home_hits
      WHERE next_page IS NOT NULL
      GROUP BY next_page
      ORDER BY COUNT(*) DESC NULLS LAST
      LIMIT 1 )        AS MOST_COMMON_NEXT_PAGE,

    /* longest time (seconds) spent on “/home…” before the next hit */
    ( SELECT MAX(time_spent_secs)
      FROM home_hits
      WHERE next_page IS NOT NULL ) AS MAX_TIME_SPENT_SECS;