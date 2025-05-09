/* -----------------------------------------------------------------
   Longest span (in days) between a user’s very first visit and the
   “last recorded event” ( first-transaction if it exists, otherwise
   the last-visit ) — but only for users whose last-recorded event
   occurred on a MOBILE device.
----------------------------------------------------------------- */

WITH all_sessions AS (          -- 1)  UNION-ALL the daily GA tables
    /*  ------  sample of daily tables  (list every table explicitly)  ------ */
    SELECT  "fullVisitorId",
            "date",
            "totals":"transactions"::NUMBER    AS "txn",
            "device":"deviceCategory"::STRING  AS device_cat
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"

    UNION ALL SELECT "fullVisitorId","date","totals":"transactions"::NUMBER AS "txn",
                     "device":"deviceCategory"::STRING                       AS device_cat
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160802"

    UNION ALL SELECT "fullVisitorId","date","totals":"transactions"::NUMBER AS "txn",
                     "device":"deviceCategory"::STRING                       AS device_cat
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160803"

    /*  … repeat a UNION ALL SELECT for EVERY remaining GA_SESSIONS_YYYYMMDD
        table up to and including 20170801 … */

    UNION ALL SELECT "fullVisitorId","date","totals":"transactions"::NUMBER AS "txn",
                     "device":"deviceCategory"::STRING                       AS device_cat
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170801"
),

/* 2) first visit per user -------------------------------------------------- */
first_visit AS (
    SELECT  "fullVisitorId",
            MIN("date") AS first_visit_date
    FROM    all_sessions
    GROUP BY "fullVisitorId"
),

/* 3) first transaction per user ------------------------------------------- */
first_txn AS (
    SELECT  "fullVisitorId",
            MIN("date") AS first_txn_date
    FROM    all_sessions
    WHERE   "txn" > 0
    GROUP BY "fullVisitorId"
),

/* 4) last visit per user --------------------------------------------------- */
last_visit AS (
    SELECT  "fullVisitorId",
            MAX("date") AS last_visit_date
    FROM    all_sessions
    GROUP BY "fullVisitorId"
),

/* 5) choose last-recorded event (first-txn preferred) ---------------------- */
chosen_event AS (
    SELECT  fv."fullVisitorId",
            fv.first_visit_date,
            COALESCE(ft.first_txn_date, lv.last_visit_date) AS last_recorded_date
    FROM    first_visit fv
    LEFT JOIN first_txn ft ON fv."fullVisitorId" = ft."fullVisitorId"
    JOIN     last_visit lv ON fv."fullVisitorId" = lv."fullVisitorId"
),

/* 6) keep only users whose chosen event happened on a MOBILE session ------- */
mobile_last_event AS (
    SELECT  ce.*
    FROM    chosen_event ce
    JOIN    all_sessions s
           ON  ce."fullVisitorId"   = s."fullVisitorId"
          AND ce.last_recorded_date = s."date"
    WHERE   s.device_cat = 'mobile'
),

/* 7) compute day span ------------------------------------------------------ */
spans AS (
    SELECT  "fullVisitorId",
            DATEDIFF('day', first_visit_date, last_recorded_date) AS days_between
    FROM    mobile_last_event
)

/* 8) final result ---------------------------------------------------------- */
SELECT  MAX(days_between) AS longest_days_between
FROM    spans;