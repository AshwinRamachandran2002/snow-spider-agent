WITH cohort AS (
  -- users whose first session_start falls between 1–15 Aug 2018
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS cohort_date
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND event_name = 'session_start'
  GROUP BY
    user_pseudo_id
),
first_quickplay AS (
  -- each user’s first quick‑play event within the cohort window
  SELECT
    user_pseudo_id,
    ANY_VALUE(event_name) AS quickplay_event_type
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND LOWER(event_name) LIKE '%quickplay%'
  GROUP BY
    user_pseudo_id
),
retained AS (
  -- cohort users who produced a session_start 8–14 days after cohort date
  SELECT DISTINCT
    c.user_pseudo_id
  FROM
    cohort c
  JOIN
    `firebase-public-project.analytics_153293282.events_*` e
  ON
    e.user_pseudo_id = c.user_pseudo_id
  WHERE
    e.event_name = 'session_start'
    AND PARSE_DATE('%Y%m%d', e.event_date)
        BETWEEN DATE_ADD(c.cohort_date, INTERVAL 8 DAY)
            AND DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
)
SELECT
  fq.quickplay_event_type,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
                    COUNT(DISTINCT c.user_pseudo_id)), 4) AS second_week_retention_rate
FROM
  cohort c
JOIN
  first_quickplay fq
ON
  c.user_pseudo_id = fq.user_pseudo_id          -- include only users who had a quick‑play event
LEFT JOIN
  retained r
ON
  c.user_pseudo_id = r.user_pseudo_id
GROUP BY
  fq.quickplay_event_type
ORDER BY
  second_week_retention_rate ASC,
  fq.quickplay_event_type
LIMIT 1;