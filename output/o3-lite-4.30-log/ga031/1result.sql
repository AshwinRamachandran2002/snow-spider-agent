WITH page_view_hits AS (
  SELECT
    CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1
    ) AS INT64) AS session_id,
    LOWER((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1
    )) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
    AND event_date = '20210102'
),
session_flags AS (
  SELECT
    session_id,
    MAX(page_title = 'home')                  AS has_home,
    MAX(page_title = 'checkout confirmation') AS has_checkout
  FROM page_view_hits
  WHERE session_id IS NOT NULL
  GROUP BY session_id
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(has_home AND has_checkout),
      COUNTIF(has_home)
    ),
    4
  ) AS conversion_rate
FROM session_flags;