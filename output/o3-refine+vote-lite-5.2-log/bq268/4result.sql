-- longest span (in days) between a user’s first visit and
-- their last recorded event (either the last visit **or** the first transaction),
-- where that last recorded event happened on a mobile‑device session
WITH sessions AS (
  SELECT
      fullVisitorId,
      visitStartTime,                              -- integer POSIX seconds
      IFNULL(totals.transactions,0) AS transactions,
      device.isMobile          AS is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- per‑user milestones
per_user AS (
  SELECT
      fullVisitorId,
      MIN(visitStartTime)                                              AS first_visit_st,
      MAX(visitStartTime)                                              AS last_visit_st,
      MIN(IF(transactions > 0, visitStartTime, NULL))                  AS first_transaction_st
  FROM sessions
  GROUP BY fullVisitorId
),

-- decide what “last recorded event” means for each user
last_event AS (
  SELECT
      fullVisitorId,
      first_visit_st,
      -- if the user ever transacted, use the first transaction;
      -- otherwise use the chronologically last visit
      CASE
          WHEN first_transaction_st IS NOT NULL THEN first_transaction_st
          ELSE last_visit_st
      END AS last_event_st
  FROM per_user
),

-- keep only those users whose chosen “last event” happened on a mobile session
last_event_mobile AS (
  SELECT
      l.fullVisitorId,
      l.first_visit_st,
      l.last_event_st
  FROM last_event            AS l
  JOIN sessions              AS s
    ON  l.fullVisitorId = s.fullVisitorId
    AND l.last_event_st = s.visitStartTime      -- match exactly that session
  WHERE s.is_mobile = TRUE                      -- must be a mobile device
),

-- compute day‑span for each qualified user
spans AS (
  SELECT
      fullVisitorId                                   AS user_id,
      DATE(TIMESTAMP_SECONDS(first_visit_st))         AS first_visit_date,
      DATE(TIMESTAMP_SECONDS(last_event_st))          AS last_event_date,
      DATE_DIFF(
          DATE(TIMESTAMP_SECONDS(last_event_st)),
          DATE(TIMESTAMP_SECONDS(first_visit_st)),
          DAY)                                        AS days_between
  FROM last_event_mobile
)

-- longest span (ties broken by user_id for determinism)
SELECT *
FROM spans
ORDER BY days_between DESC, user_id
LIMIT 1;