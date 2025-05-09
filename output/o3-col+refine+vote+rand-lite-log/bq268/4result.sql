-- Longest gap (in days) between a user’s first visit and their last recorded   
-- event (last visit OR first transaction), keeping only users whose last event
-- happened on a mobile device.  Returns every user that shares the maximum gap.

WITH visits AS (                         -- first & last visit per user
  SELECT
    fullVisitorId,
    MIN(date) AS first_visit_date,
    MAX(date) AS last_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),
transactions AS (                        -- first transaction per user
  SELECT
    fullVisitorId,
    MIN(date) AS first_transaction_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions > 0
  GROUP BY fullVisitorId
),
chosen_event AS (                        -- decide the “last event” date
  SELECT
    v.fullVisitorId,
    v.first_visit_date,
    COALESCE(t.first_transaction_date, v.last_visit_date) AS last_event_date
  FROM visits v
  LEFT JOIN transactions t USING (fullVisitorId)
),
mobile_last AS (                         -- was that last event on mobile?
  SELECT
    e.*,
    ANY_VALUE(s.device.isMobile) AS last_event_is_mobile
  FROM   chosen_event            AS e
  JOIN   `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
         ON  s.fullVisitorId = e.fullVisitorId
         AND s.date          = e.last_event_date
  GROUP BY e.fullVisitorId, e.first_visit_date, e.last_event_date
),
gap AS (                                 -- day difference for mobile-only rows
  SELECT
    fullVisitorId,
    first_visit_date,
    last_event_date,
    DATE_DIFF(PARSE_DATE('%Y%m%d', last_event_date),
              PARSE_DATE('%Y%m%d', first_visit_date),
              DAY) AS days_between
  FROM mobile_last
  WHERE last_event_is_mobile = TRUE
)
SELECT *
FROM   gap
WHERE  days_between = (SELECT MAX(days_between) FROM gap);