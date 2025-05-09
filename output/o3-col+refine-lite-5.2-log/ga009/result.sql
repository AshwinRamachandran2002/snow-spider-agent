/*  Average number of engaged sessions per user during December‑2020            */
/*  – a session is (user_pseudo_id, ga_session_id) where session_engaged = 1   */

WITH event_level AS (          -- 1 row per (user,event) with the 2 parameters we need
  SELECT
    user_pseudo_id,
    MAX(IF(ep.key = 'ga_session_id', ep.value.int_value, NULL))                                             AS ga_session_id,
    MAX(IF(ep.key = 'session_engaged',
            COALESCE(SAFE_CAST(ep.value.string_value AS INT64), ep.value.int_value),
            NULL))                                                                                          AS session_engaged_flag
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
       UNNEST(event_params) AS ep
  GROUP BY _TABLE_SUFFIX, user_pseudo_id, event_timestamp
),

sessions AS (                  -- keep only the engaged sessions (flag = 1)
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id
  FROM event_level
  WHERE session_engaged_flag = 1
),

user_session_counts AS (       -- count engaged sessions per user
  SELECT
    user_pseudo_id,
    COUNT(ga_session_id) AS engaged_sessions
  FROM sessions
  GROUP BY user_pseudo_id
)

SELECT                         -- finally, average across users
  AVG(engaged_sessions) AS avg_engaged_sessions_per_user
FROM user_session_counts;