SELECT
  AVG(total_engaged_sessions) AS Average_Engaged_Sessions_Per_User
FROM (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS total_engaged_sessions
  FROM (
    SELECT
      t.user_pseudo_id,
      MAX(IF(ep.key = 'session_engaged', ep.value.string_value, NULL)) AS session_engaged,
      MAX(IF(ep.key = 'ga_session_id', ep.value.int_value, NULL)) AS ga_session_id
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS t
    CROSS JOIN
      UNNEST(t.event_params) AS ep
    WHERE
      _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    GROUP BY
      t.user_pseudo_id,
      t.event_timestamp
  )
  WHERE
    session_engaged = '1' AND ga_session_id IS NOT NULL
  GROUP BY
    user_pseudo_id
)