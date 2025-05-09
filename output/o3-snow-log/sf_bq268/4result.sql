WITH sessions AS (     -- every session row with the fields we need
    SELECT  "fullVisitorId"::STRING                     AS full_visitor_id ,
            "visitStartTime"::NUMBER                    AS visit_ts ,
            "device":"isMobile"::BOOLEAN                AS is_mobile
    FROM    "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160801"
),
transactions AS (      -- first-ever transaction per user (if any)
    SELECT  "fullVisitorId"::STRING                     AS full_visitor_id ,
            MIN("visitStartTime"::NUMBER)               AS first_transaction_ts
    FROM    "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160801"
    WHERE   "totals":"totalTransactionRevenue" IS NOT NULL
    GROUP BY "fullVisitorId"
),
per_user AS (          -- first visit, last visit, and (optional) first transaction
    SELECT  s.full_visitor_id ,
            MIN(s.visit_ts)                            AS first_visit_ts ,
            MAX(s.visit_ts)                            AS last_visit_ts ,
            t.first_transaction_ts
    FROM    sessions s
    LEFT JOIN transactions t
           ON s.full_visitor_id = t.full_visitor_id
    GROUP BY s.full_visitor_id , t.first_transaction_ts
),
last_event AS (        -- decide which timestamp is the “last recorded event”
    SELECT  full_visitor_id ,
            first_visit_ts ,
            GREATEST( last_visit_ts ,
                      COALESCE(first_transaction_ts , 0) ) AS last_event_ts
    FROM    per_user
),
last_event_device AS ( -- bring in the device flag for that last event
    SELECT  l.* ,
            s.is_mobile
    FROM    last_event l
    JOIN    sessions s
          ON l.full_visitor_id = s.full_visitor_id
         AND l.last_event_ts  = s.visit_ts
)
-- final answer: longest # of days between first visit and last event
SELECT  MAX(
            DATEDIFF(
                'day',
                TO_TIMESTAMP_NTZ(first_visit_ts),
                TO_TIMESTAMP_NTZ(last_event_ts)
            )
       ) AS longest_days_between_first_and_last_mobile_event
FROM    last_event_device
WHERE   is_mobile = TRUE;