-- distinct pseudo‑users with positive engagement time in the
-- 7‑day window ending 2021‑01‑07 23:59:59 that did NOT have
-- positive engagement time in the 2‑day window ending at the same moment
WITH engagement AS (
  SELECT
    user_pseudo_id,
    _TABLE_SUFFIX AS event_date
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(event_params) AS ep
  WHERE
        -- keep only tables (dates) we care about
        _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND event_name = 'user_engagement'
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0                   -- positive engagement time
),
seven_day_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement                                  -- already limited to 20210101‑20210107
),
two_day_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210106' AND '20210107' -- 2‑day window
)
SELECT COUNT(*) AS distinct_users
FROM seven_day_users
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM two_day_users);