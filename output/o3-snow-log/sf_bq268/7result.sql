/*  Longest span (in days) between a user’s first visit and the
    “last recorded event” (either the last visit *or* the first
    transaction), considering only users whose last recorded event
    happened on a mobile device.                                    */

WITH base AS (       -- consolidate the two available daily tables
    SELECT "fullVisitorId",
           TO_DATE("date",'YYYYMMDD')                       AS visit_d,
           "device"::VARIANT:"deviceCategory"::STRING       AS dev_cat,
           "totals"::VARIANT:"transactions"                AS tx
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"
    
    UNION ALL
    
    SELECT "fullVisitorId",
           TO_DATE("date",'YYYYMMDD')                       AS visit_d,
           "device"::VARIANT:"deviceCategory"::STRING       AS dev_cat,
           "totals"::VARIANT:"transactions"                AS tx
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160802"
),

/* first visit per user */
first_vis AS (
    SELECT "fullVisitorId",
           MIN(visit_d) AS first_d
    FROM   base
    GROUP BY "fullVisitorId"
),

/* first-ever transaction date per user (if any) */
first_tx AS (
    SELECT "fullVisitorId",
           MIN(visit_d) AS first_tx_d
    FROM   base
    WHERE  tx IS NOT NULL
    GROUP BY "fullVisitorId"
),

/* most-recent visit per user (keeping its device category) */
last_vis AS (
    SELECT  "fullVisitorId",
            visit_d  AS last_visit_d,
            dev_cat  AS last_visit_dev
    FROM  (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY "fullVisitorId"
                                  ORDER BY visit_d DESC) AS rn
        FROM   base
    ) v
    WHERE  rn = 1
),

/* choose the “last recorded event” (greater of last visit vs. first txn) */
last_event AS (
    SELECT  fv."fullVisitorId",
            fv.first_d,
            /* later of the two dates */
            GREATEST(lv.last_visit_d,
                     COALESCE(ft.first_tx_d, lv.last_visit_d)) AS last_evt_d,
            lv.last_visit_dev
    FROM    first_vis fv
    LEFT    JOIN first_tx  ft ON fv."fullVisitorId" = ft."fullVisitorId"
    JOIN    last_vis   lv ON fv."fullVisitorId" = lv."fullVisitorId"
    /* keep only users whose *last recorded event* device is mobile */
    WHERE   lv.last_visit_dev ILIKE '%mobile%'
)

/* finally, compute the longest span in days */
SELECT MAX(DATEDIFF('day', first_d, last_evt_d)) AS max_days_between_first_and_last
FROM   last_event;