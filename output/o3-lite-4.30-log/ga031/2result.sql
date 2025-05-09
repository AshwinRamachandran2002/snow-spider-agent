WITH page_views AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id') AS ga_session_id,
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'page_title')    AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date = '20210102'
    AND event_name = 'page_view'
),
sessions AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    ARRAY_AGG(DISTINCT page_title IGNORE NULLS) AS pages
  FROM page_views
  GROUP BY user_pseudo_id, ga_session_id
),
counts AS (
  SELECT
    COUNTIF('Home' IN UNNEST(pages)) AS sessions_with_home,
    COUNTIF('Home' IN UNNEST(pages) AND 'Checkout Confirmation' IN UNNEST(pages))
      AS sessions_home_and_checkout
  FROM sessions
)
SELECT
  ROUND(SAFE_DIVIDE(sessions_home_and_checkout, sessions_with_home) * 100, 4) AS conversion_rate
FROM counts;