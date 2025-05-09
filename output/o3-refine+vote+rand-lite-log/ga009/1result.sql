-- Average number of engaged sessions per user in December 2020
WITH engaged_events AS (
  SELECT
    user_pseudo_id,
    -- grab the ga_session_id attached to the event
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id') AS ga_session_id
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    -- restrict to December 2020 tables
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    -- keep only events where session_engaged = 1
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'session_engaged'
        AND (ep.value.string_value = '1' OR ep.value.int_value = 1)
    )
)
, per_user AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions
  FROM
    engaged_events
  WHERE
    ga_session_id IS NOT NULL
  GROUP BY
    user_pseudo_id
)
SELECT
  AVG(engaged_sessions) AS avg_engaged_sessions_per_user
FROM
  per_user;