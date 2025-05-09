WITH quickplays AS (  -- all quick‑play events in the cohort window
  SELECT
    user_pseudo_id,
    (SELECT p.value.string_value
       FROM UNNEST(event_params) AS p
      WHERE p.key = 'board'
      LIMIT 1)                             AS quickplay_type,
    event_timestamp,
    event_date,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id
                       ORDER BY event_timestamp) AS rn
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND LOWER(event_name) LIKE '%quickplay%'
),
cohort AS (  -- first quick‑play per user who also had a session_start
  SELECT
    q.user_pseudo_id,
    PARSE_DATE('%Y%m%d', q.event_date) AS first_qp_date,
    q.quickplay_type
  FROM quickplays q
  JOIN (
        SELECT DISTINCT user_pseudo_id
        FROM `firebase-public-project.analytics_153293282.events_*`
        WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
          AND event_name = 'session_start'
       ) s
    ON s.user_pseudo_id = q.user_pseudo_id
  WHERE q.rn = 1
    AND q.quickplay_type IS NOT NULL
),
retention AS (  -- session_start exactly 14 days later
  SELECT
    c.quickplay_type,
    COUNT(DISTINCT c.user_pseudo_id) AS cohort_size,
    COUNT(DISTINCT r.user_pseudo_id) AS retained_users
  FROM cohort c
  LEFT JOIN (
        SELECT
          user_pseudo_id,
          PARSE_DATE('%Y%m%d', event_date) AS sess_date
        FROM `firebase-public-project.analytics_153293282.events_*`
        WHERE _TABLE_SUFFIX BETWEEN '20180716' AND '20180730'
          AND event_name = 'session_start'
       ) r
    ON  r.user_pseudo_id = c.user_pseudo_id
    AND r.sess_date      = DATE_ADD(c.first_qp_date, INTERVAL 14 DAY)
  GROUP BY c.quickplay_type
)
SELECT
  quickplay_type                                              AS quickplay_event_type,
  ROUND(SAFE_DIVIDE(retained_users, cohort_size), 4)          AS retention_rate_two_weeks
FROM retention
ORDER BY quickplay_event_type;