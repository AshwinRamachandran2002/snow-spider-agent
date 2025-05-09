/*--------------------------------------------------------------
  January-2017  – “Data Share” sessions that touched “/home%”
  • most common page visited right AFTER a “/home%” page
  • maximum time-on-home (sec) before the next hit
--------------------------------------------------------------*/
WITH jan_sessions AS (          -- 31 daily tables, unioned explicitly
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

/* keep only “Data Share” campaigns */
filtered_sessions AS (
    SELECT
        s."fullVisitorId",
        s."visitId",
        PARSE_JSON(s."hits") AS hits_array
    FROM jan_sessions s
    WHERE PARSE_JSON(s."trafficSource"):"campaign"::STRING ILIKE '%data%share%'
),

/* explode hits */
hits_flat AS (
    SELECT
        fs."fullVisitorId",
        fs."visitId",
        h.value:"hitNumber"::NUMBER        AS hit_num,
        h.value:"time"::NUMBER             AS hit_time,
        h.value:"page":"pagePath"::STRING  AS page_path
    FROM filtered_sessions fs,
         LATERAL FLATTEN(input => fs.hits_array) h
),

/* isolate “/home%” hits and compute the immediate next hit */
home_hits AS (
    SELECT
        hf.*,
        LEAD(hf.page_path) OVER (PARTITION BY hf."fullVisitorId", hf."visitId"
                                 ORDER BY hf.hit_num)        AS next_page,
        LEAD(hf.hit_time)  OVER (PARTITION BY hf."fullVisitorId", hf."visitId"
                                 ORDER BY hf.hit_num)        AS next_hit_time
    FROM hits_flat hf
    WHERE hf.page_path ILIKE '/home%'
),

/* rows where a next page exists */
valid_rows AS (
    SELECT
        next_page,
        (next_hit_time - hit_time) / 1000.0  AS time_on_home_sec
    FROM home_hits
    WHERE next_page IS NOT NULL
)

/* final answer */
SELECT
    /* most common page visited after “/home%” */
    ( SELECT next_page
      FROM valid_rows
      GROUP BY next_page
      ORDER BY COUNT(*) DESC NULLS LAST
      LIMIT 1
    )                                                         AS most_common_next_page,

    /* maximum seconds spent on a “/home%” page before moving on */
    ( SELECT MAX(time_on_home_sec) FROM valid_rows )          AS max_time_on_home_seconds;