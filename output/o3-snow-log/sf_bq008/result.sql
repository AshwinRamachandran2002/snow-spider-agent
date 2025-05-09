WITH jan_sessions AS (

    /* =================  All 31 daily tables for January-2017  ================= */
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

/* --------  Extract every hit, plus “next” hit information, for the required audience  -------- */
home_hits AS (
    SELECT
        t."fullVisitorId",
        t."visitId",
        f.value:"page":"pagePath"::STRING  AS pagePath,
        f.value:"time"::NUMBER             AS offset_ms,

        /* next page and its timestamp, within the same session */
        LEAD( f.value:"page":"pagePath"::STRING )
        OVER (PARTITION BY t."fullVisitorId", t."visitId"
              ORDER BY f.value:"hitNumber"::NUMBER)                    AS nextPage,

        LEAD( f.value:"time"::NUMBER )
        OVER (PARTITION BY t."fullVisitorId", t."visitId"
              ORDER BY f.value:"hitNumber"::NUMBER)                    AS nextOffset
    FROM   jan_sessions t,
           LATERAL FLATTEN( INPUT => t."hits")                         f
    WHERE  t."trafficSource":"campaign"::STRING ILIKE '%Data%Share%'
)

/* ===========================  Final answers  =========================== */
SELECT
       /* Most-frequent page visited immediately after a “/home…” hit */
       (
         SELECT   nextPage
         FROM     home_hits
         WHERE    pagePath ILIKE '/home%'          -- only “/home…” hits
           AND    nextPage IS NOT NULL             -- ignore missing next page
         GROUP BY nextPage
         ORDER BY COUNT(*) DESC NULLS LAST
         LIMIT 1
       )                                           AS most_common_next_page,

       /* Maximum dwell time on a “/home…” page before next hit (sec) */
       (
         SELECT  MAX( (nextOffset - offset_ms) / 1000 )
         FROM    home_hits
         WHERE   pagePath ILIKE '/home%'           -- only “/home…” hits
           AND   nextOffset IS NOT NULL            -- need a following hit
       )                                           AS max_time_spent_sec;