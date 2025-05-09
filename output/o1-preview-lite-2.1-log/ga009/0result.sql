SELECT
  AVG(engaged_sessions_per_user) AS average_engaged_sessions_per_user
FROM (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions_per_user
  FROM (
    SELECT
      user_pseudo_id,
      MAX(IF(ep.key = 'ga_session_id', CAST(ep.value.int_value AS STRING), NULL)) AS ga_session_id,
      MAX(IF(ep.key = 'session_engaged', CAST(ep.value.int_value AS INT64), NULL)) AS session_engaged
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS t,
      UNNEST(t.event_params) AS ep
    WHERE
      _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    GROUP BY
      user_pseudo_id, event_timestamp
  )
  WHERE
    session_engaged = 1 AND ga_session_id IS NOT NULL
  GROUP BY
    user_pseudo_id
)