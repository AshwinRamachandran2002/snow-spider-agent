-- longest span (in days) between a user's very first visit
-- and her “last recorded event”, where that last event
-- is   • the first transaction if the user ever purchased, or
--     • the very last visit otherwise,
-- and the session that contains this last‑event happened on a mobile device
WITH sessions AS (
  SELECT
      fullVisitorId                          AS user_id ,
      visitStartTime                         AS visit_ts ,         -- seconds since epoch
      IFNULL(totals.transactions,0)          AS transactions ,
      device.isMobile                        AS is_mobile
  FROM   `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

/* basic per‑user milestones (timestamps expressed in seconds) */
user_milestones AS (
  SELECT
      user_id ,
      MIN(visit_ts)                                               AS first_visit_ts ,
      MIN( IF(transactions>0 , visit_ts , NULL) )                 AS first_txn_ts ,
      MAX(visit_ts)                                               AS last_visit_ts
  FROM   sessions
  GROUP  BY user_id
),

/* choose the appropriate “last recorded event” for every user */
event_choice AS (
  SELECT
      user_id ,
      first_visit_ts ,
      IF(first_txn_ts IS NULL , last_visit_ts , first_txn_ts)     AS event_ts
  FROM   user_milestones
),

/* keep only users whose chosen last‑event session was on a mobile device */
mobile_final_event AS (
  SELECT DISTINCT
      ec.user_id ,
      ec.first_visit_ts ,
      ec.event_ts
  FROM   event_choice ec
  JOIN   sessions s
         ON  s.user_id = ec.user_id
         AND s.visit_ts = ec.event_ts          -- the exact session that hosts the last event
  WHERE  s.is_mobile = TRUE                    -- must be a mobile session
)

/* compute day span and pick the maximum one */
SELECT
    user_id ,
    DATE_DIFF(DATE(TIMESTAMP_SECONDS(event_ts)),
              DATE(TIMESTAMP_SECONDS(first_visit_ts)),
              DAY)                               AS days_between
FROM   mobile_final_event
ORDER  BY days_between DESC
LIMIT  1;