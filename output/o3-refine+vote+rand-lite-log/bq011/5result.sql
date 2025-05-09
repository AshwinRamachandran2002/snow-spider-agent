/* distinct pseudo‑users with positive engagement in
   Jan 1 – Jan 7 2021 but NOT in Jan 6 – Jan 7 2021 */
WITH engagement AS (
  SELECT DISTINCT
         user_pseudo_id,
         _TABLE_SUFFIX AS event_date          -- YYYYMMDD derived from table name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'   -- 7‑day window
        AND event_name = 'user_engagement'
        AND ep.key = 'engagement_time_msec'               -- engagement time parameter
        AND (ep.value.int_value  > 0                      -- positive engagement
             OR ep.value.float_value  > 0
             OR ep.value.double_value > 0)
),

-- users with any positive engagement in the 7‑day window
seven_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
),

-- users with positive engagement in the final 2‑day window (Jan 6–7)
two_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210106' AND '20210107'
)

SELECT COUNT(*) AS distinct_users
FROM seven_day
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM two_day);