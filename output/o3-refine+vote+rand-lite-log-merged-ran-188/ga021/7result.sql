/* 14-day retention for every quick-play event type
   cohort: users who fired a session_start between 02-Jul-2018 and 16-Jul-2018      */

WITH cohort_users AS (          -- users in scope
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),

first_quickplay AS (            -- first quick-play per user & type + the exact D+14 date
  SELECT
    qp.user_pseudo_id,
    qp.event_name,
    MIN(PARSE_DATE('%Y%m%d', qp.event_date))                                                  AS first_event_date,
    FORMAT_DATE('%Y%m%d',
      DATE_ADD(MIN(PARSE_DATE('%Y%m%d', qp.event_date)), INTERVAL 14 DAY))                    AS target_date_str
  FROM `firebase-public-project.analytics_153293282.events_*` qp
  WHERE qp._TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND LOWER(qp.event_name) LIKE '%quickplay%'
    AND qp.user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
  GROUP BY qp.user_pseudo_id, qp.event_name
),

returns AS (                    -- users who repeated the *same* quick-play event exactly 14 days later
  SELECT DISTINCT
    fq.user_pseudo_id,
    fq.event_name
  FROM first_quickplay           AS fq
  JOIN `firebase-public-project.analytics_153293282.events_*` AS r
    ON  r.user_pseudo_id = fq.user_pseudo_id
    AND r.event_name     = fq.event_name
    AND r._TABLE_SUFFIX  = fq.target_date_str                 -- fires on precise calendar day D+14
    -- target dates run between 20180716 and 20180730, so limit the scan a bit
  WHERE r._TABLE_SUFFIX BETWEEN '20180716' AND '20180730'
)

SELECT
  fq.event_name,
  COUNT(DISTINCT fq.user_pseudo_id)                                 AS total_users,
  COUNT(DISTINCT re.user_pseudo_id)                                 AS retained_users,
  ROUND(
        SAFE_DIVIDE(COUNT(DISTINCT re.user_pseudo_id),
                    COUNT(DISTINCT fq.user_pseudo_id))*100, 2)      AS retention_rate_14d_pct
FROM first_quickplay AS fq
LEFT JOIN returns   AS re
  ON  re.user_pseudo_id = fq.user_pseudo_id
  AND re.event_name     = fq.event_name
GROUP BY fq.event_name
ORDER BY fq.event_name;