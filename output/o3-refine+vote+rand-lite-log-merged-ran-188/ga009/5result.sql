-- average engaged‑session count per user for December‑2020
WITH base AS (
  SELECT
    user_pseudo_id,
    -- grab ga_session_id for the row
    (SELECT value.int_value
     FROM UNNEST(event_params)
     WHERE key = 'ga_session_id'
           AND value.int_value IS NOT NULL
     LIMIT 1)                               AS ga_session_id,
    -- grab session_engaged flag (can be string or int)
    (SELECT COALESCE(CAST(value.int_value AS STRING), value.string_value)
     FROM UNNEST(event_params)
     WHERE key = 'session_engaged'
     LIMIT 1)                               AS session_engaged
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'          -- all December‑2020 daily tables
),
engaged_sessions AS (
  -- keep only sessions with session_engaged = '1'
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id
  FROM base
  WHERE session_engaged = '1'
        AND ga_session_id IS NOT NULL               -- need session id to identify session
),
per_user AS (
  -- count engaged sessions for each user
  SELECT
    user_pseudo_id,
    COUNT(*) AS engaged_session_count
  FROM engaged_sessions
  GROUP BY user_pseudo_id
)
-- average number of engaged sessions per user
SELECT
  AVG(engaged_session_count) AS avg_engaged_sessions_per_user
FROM per_user;