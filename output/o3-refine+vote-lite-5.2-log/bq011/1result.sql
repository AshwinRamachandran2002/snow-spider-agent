-- distinct pseudo‑users that showed engagement in the last 7‑day window
-- (2021‑01‑01 … 2021‑01‑07) but NOT in the last 2‑day window
-- (2021‑01‑06 … 2021‑01‑07)
WITH engagement AS (          -- every calendar day on which the user had >0 engagement
  SELECT
      user_pseudo_id,
      _TABLE_SUFFIX AS event_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'          -- 7‑day window
    AND event_name = 'user_engagement'
    AND EXISTS (                                                 -- positive engagement time
          SELECT 1
          FROM UNNEST(event_params) p
          WHERE p.key = 'engagement_time_msec'
            AND p.value.int_value > 0 )
  GROUP BY user_pseudo_id, event_date
),
flags AS (                    -- does the user engage in each window?
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN event_date BETWEEN '20210101' AND '20210107' THEN 1 END) AS in_7d,
    MAX(CASE WHEN event_date BETWEEN '20210106' AND '20210107' THEN 1 END) AS in_2d
  FROM engagement
  GROUP BY user_pseudo_id
)
SELECT COUNT(*) AS distinct_users
FROM flags
WHERE in_7d = 1      -- engaged sometime in the 7‑day window
  AND in_2d = 0;     -- but NOT in the last 2 days