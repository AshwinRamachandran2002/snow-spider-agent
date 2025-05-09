/* Two-week (14-20 days) retention by quick-play event type
   ─ Cohort users: first session_start occurred 02-Jul-2018–16-Jul-2018
   ─ First quick-play: user’s earliest quick-play event in that same period
   ─ Retained users: performed the SAME quick-play again 14–20 days later
*/
WITH cohort_users AS (          -- 1️⃣ users whose first session is in the cohort window
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),

first_quickplay AS (            -- 2️⃣ first quick-play event per user & type
  SELECT
    e.user_pseudo_id,
    e.event_name                          AS quickplay_event,
    MIN(e.event_timestamp) AS first_qp_ts -- microseconds
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN cohort_users cu
    ON cu.user_pseudo_id = e.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND LOWER(e.event_name) LIKE '%quickplay%'
  GROUP BY e.user_pseudo_id, e.event_name
),

retained AS (                   -- 3️⃣ same quick-play repeated 14-20 days later
  SELECT DISTINCT
         fq.user_pseudo_id,
         fq.quickplay_event
  FROM first_quickplay fq
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = fq.user_pseudo_id
   AND e.event_name     = fq.quickplay_event
   AND e.event_timestamp >= fq.first_qp_ts + 14*24*60*60*1000000
   AND e.event_timestamp <  fq.first_qp_ts + 21*24*60*60*1000000
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'  -- cover look-ahead days
)

-- 4️⃣ final retention table
SELECT
  fq.quickplay_event,
  COUNT(DISTINCT fq.user_pseudo_id) AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)  AS retained_users,
  ROUND(
    SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
                COUNT(DISTINCT fq.user_pseudo_id)), 4) AS retention_rate_2week
FROM first_quickplay fq
LEFT JOIN retained r
       ON  r.user_pseudo_id  = fq.user_pseudo_id
      AND r.quickplay_event  = fq.quickplay_event
GROUP BY fq.quickplay_event
ORDER BY retention_rate_2week DESC;