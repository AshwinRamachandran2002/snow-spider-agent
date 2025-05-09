/* distinct pseudo‑users that
   – had positive engagement time at least once between 2021‑01‑01 and 2021‑01‑07 (inclusive)
   – but had 0 such occurrences on 2021‑01‑06 or 2021‑01‑07                               */

WITH engagement AS (
  SELECT
    user_pseudo_id,
    _TABLE_SUFFIX AS event_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021010*`
  CROSS JOIN UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'      -- 7‑day window
    AND event_name = 'user_engagement'                       -- engagement event
    AND ep.key  = 'engagement_time_msec'                     -- look at engagement time
    AND ep.value.int_value > 0                               -- positive engagement
    AND user_pseudo_id IS NOT NULL
),

engaged_7d AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement                                         -- any day in 7‑day window
),

engaged_2d AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210106' AND '20210107'       -- last 2 days
)

SELECT COUNT(*) AS distinct_pseudo_users
FROM engaged_7d
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM engaged_2d);