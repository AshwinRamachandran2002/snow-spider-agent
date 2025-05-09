WITH session_pages AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value
     FROM UNNEST(event_params)
     WHERE key = 'ga_session_id'
     LIMIT 1) AS ga_session_id,
    MAX(IF(ep.key = 'page_title' AND ep.value.string_value = 'Home', 1, 0)) AS has_home,
    MAX(IF(ep.key = 'page_title' AND ep.value.string_value = 'Checkout Confirmation', 1, 0)) AS has_confirmation
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS ep
  WHERE event_date = '20210102'
    AND event_name = 'page_view'
  GROUP BY
    user_pseudo_id,
    ga_session_id
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(has_home = 1 AND has_confirmation = 1),
      COUNTIF(has_home = 1)
    ) * 100,
    4
  ) AS conversion_rate
FROM session_pages;