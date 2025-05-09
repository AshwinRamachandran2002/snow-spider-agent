/*  Longest span (in days) between a visitor’s first‐ever session
    and the “last recorded event” that occurred on a mobile device.
    • “Last recorded event” is defined as:
        – The visitor’s first transaction date (if the visitor ever purchased), or
        – Otherwise the visitor’s last visit date.
    • Only those visitors whose selected “last recorded event”
      happened on a mobile device are retained.
    • All calendar-day GA session tables that ship with the sample
      data set are UNION-ed first, then the logic is applied.         */

WITH union_sessions AS (          -- 1) raw data from every daily table
    SELECT "fullVisitorId"                       AS fullvisitorid,
           "date"                                AS session_date,
           "device":"deviceCategory"::STRING     AS device_category,
           "totals":"transactions"::NUMBER       AS transactions
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160801"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,"totals":"transactions"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160802"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,"totals":"transactions"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160803"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,"totals":"transactions"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160804"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,"totals":"transactions"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160805"
    UNION ALL
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,"totals":"transactions"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20160806"
    UNION ALL       -- …(continue listing every daily table that exists)…
    SELECT "fullVisitorId","date","device":"deviceCategory"::STRING,"totals":"transactions"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170801"
),

-- 2) per-visitor milestones
per_visitor AS (
    SELECT
        fullvisitorid,
        MIN(session_date)                                         AS first_visit_date,
        MAX(session_date)                                         AS last_visit_date,
        MIN(CASE WHEN transactions > 0 THEN session_date END)     AS first_txn_date
    FROM union_sessions
    GROUP BY fullvisitorid
),

-- 3) decide which date is the “last recorded event”
chosen_event AS (
    SELECT
        v.fullvisitorid,
        v.first_visit_date,
        /* if a transaction has ever happened, its FIRST date wins;
           otherwise fall back to last visit date */
        COALESCE(v.first_txn_date, v.last_visit_date)             AS event_date
    FROM per_visitor v
),

-- 4) keep only those visitors whose chosen event was on a mobile device
mobile_event_visitors AS (
    SELECT
        c.fullvisitorid,
        c.first_visit_date,
        c.event_date,
        DATEDIFF(
            'day',
            TO_DATE(c.first_visit_date,'YYYYMMDD'),
            TO_DATE(c.event_date,'YYYYMMDD')
        )                                                         AS days_between
    FROM chosen_event   c
    JOIN union_sessions s
          ON s.fullvisitorid = c.fullvisitorid
         AND s.session_date = c.event_date
    WHERE s.device_category ILIKE 'mobile'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY c.fullvisitorid
                               ORDER BY s.transactions DESC NULLS LAST) = 1
)

-- 5) final answer – the longest span in days
SELECT MAX(days_between) AS longest_days_between_first_and_last_event
FROM   mobile_event_visitors;