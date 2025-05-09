SELECT
  ROUND((sessions_with_home_and_checkout / sessions_with_home) * 100, 4) AS User_Session_Conversion_Rate
FROM (
  SELECT
    COUNT(DISTINCT CASE WHEN has_home = 1 THEN ga_session_id END) AS sessions_with_home,
    COUNT(DISTINCT CASE WHEN has_home = 1 AND has_checkout = 1 THEN ga_session_id END) AS sessions_with_home_and_checkout
  FROM (
    SELECT
      ga_session_id,
      MAX(CASE WHEN page_title = 'home' THEN 1 ELSE 0 END) AS has_home,
      MAX(CASE WHEN page_title = 'checkout confirmation' THEN 1 ELSE 0 END) AS has_checkout
    FROM (
      SELECT
        (SELECT ep.value.int_value FROM UNNEST(t.event_params) ep WHERE ep.key = 'ga_session_id') AS ga_session_id,
        LOWER((SELECT ep.value.string_value FROM UNNEST(t.event_params) ep WHERE ep.key = 'page_title')) AS page_title
      FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
      WHERE
        t.event_name = 'page_view'
    ) AS events
    GROUP BY
      ga_session_id
  ) AS sessions
)