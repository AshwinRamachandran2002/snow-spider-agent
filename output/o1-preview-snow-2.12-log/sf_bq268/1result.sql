WITH sessions AS (
  SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM (
    SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160801
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160802
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160803
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160804
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160805
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160806
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160807
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160808
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160809
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160810
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160811
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160812
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160813
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160814
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160815
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160816
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160817
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160818
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160819
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20160820
    -- Continue including all sessions tables explicitly from GA_SESSIONS_20160821 to GA_SESSIONS_20170801
    UNION ALL SELECT "fullVisitorId", "visitStartTime", "totals", "device" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170801
  )
),
first_visits AS (
  SELECT "fullVisitorId", MIN(DATE(TO_TIMESTAMP("visitStartTime"))) AS first_visit_date
  FROM sessions
  GROUP BY "fullVisitorId"
),
first_transactions AS (
  SELECT "fullVisitorId", MIN(DATE(TO_TIMESTAMP("visitStartTime"))) AS first_transaction_date
  FROM sessions
  WHERE ("totals":"transactions")::INTEGER > 0
    AND ("device":"deviceCategory")::STRING = 'mobile'
  GROUP BY "fullVisitorId"
),
last_mobile_visits AS (
  SELECT "fullVisitorId", MAX(DATE(TO_TIMESTAMP("visitStartTime"))) AS last_mobile_visit_date
  FROM sessions
  WHERE ("device":"deviceCategory")::STRING = 'mobile'
  GROUP BY "fullVisitorId"
),
last_event_dates AS (
  SELECT fv."fullVisitorId",
         fv.first_visit_date,
         COALESCE(ft.first_transaction_date, lm.last_mobile_visit_date) AS last_event_date
  FROM first_visits fv
  LEFT JOIN first_transactions ft ON fv."fullVisitorId" = ft."fullVisitorId"
  LEFT JOIN last_mobile_visits lm ON fv."fullVisitorId" = lm."fullVisitorId"
  WHERE ft.first_transaction_date IS NOT NULL OR lm.last_mobile_visit_date IS NOT NULL
),
date_differences AS (
  SELECT "fullVisitorId",
         DATEDIFF('day', first_visit_date, last_event_date) AS num_days
  FROM last_event_dates
)
SELECT MAX(num_days) AS "Longest_number_of_days"
FROM date_differences;