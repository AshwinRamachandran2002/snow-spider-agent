WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)            AS event_date,
    user_pseudo_id,
    event_name,
    event_timestamp,
    event_params
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'
),

/* Users who opened at least one session in the cohort window */
session_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM base
  WHERE event_name = 'session_start'
    AND event_date BETWEEN '2018-07-02' AND '2018-07-16'
),

/* Each user’s first quick‑play event in the cohort window */
cohort AS (
  SELECT
    user_pseudo_id,
    first_qp_date,
    quickplay_event_type
  FROM (
    SELECT
      b.user_pseudo_id,
      b.event_date                                                     AS first_qp_date,
      ( SELECT ep.value.string_value
        FROM UNNEST(b.event_params) ep
        WHERE ep.key = 'board')                                        AS quickplay_event_type,
      ROW_NUMBER() OVER (PARTITION BY b.user_pseudo_id
                         ORDER BY b.event_date, b.event_timestamp)      AS rn
    FROM base b
    JOIN session_users su USING (user_pseudo_id)
    WHERE b.event_name LIKE '%quickplay'
      AND b.event_date BETWEEN '2018-07-02' AND '2018-07-16'
  )
  WHERE rn = 1
    AND quickplay_event_type IS NOT NULL
),

/* Users who fired any quick‑play exactly 14 days after their first one */
returns AS (
  SELECT DISTINCT c.user_pseudo_id
  FROM cohort c
  JOIN base  b
    ON b.user_pseudo_id = c.user_pseudo_id
   AND b.event_name     LIKE '%quickplay'
   AND b.event_date     = DATE_ADD(c.first_qp_date, INTERVAL 14 DAY)
)

/* Two‑week retention per quick‑play type */
SELECT
  quickplay_event_type,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT r.user_pseudo_id),
      COUNT(DISTINCT c.user_pseudo_id)
    ), 4
  ) AS retention_rate_two_weeks
FROM cohort c
LEFT JOIN returns r
  ON r.user_pseudo_id = c.user_pseudo_id
GROUP BY quickplay_event_type
ORDER BY quickplay_event_type;