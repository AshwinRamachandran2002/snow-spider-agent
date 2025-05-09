-- User-session conversion rate on 2-Jan-2021 (page_view events only)
WITH base AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id'
     LIMIT 1)           AS session_id,
    LOWER((
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1))         AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
session_pages AS (
  SELECT
    user_pseudo_id,
    session_id,
    ARRAY_AGG(DISTINCT page_title) AS pages
  FROM base
  GROUP BY user_pseudo_id, session_id
),
metrics AS (
  SELECT
    COUNTIF('google online store' IN UNNEST(pages) OR 'home' IN UNNEST(pages))              AS home_sessions,
    COUNTIF(('google online store' IN UNNEST(pages) OR 'home' IN UNNEST(pages))
            AND 'checkout confirmation' IN UNNEST(pages))                                  AS converted_sessions
  FROM session_pages
)
SELECT
  converted_sessions,
  home_sessions,
  SAFE_DIVIDE(converted_sessions, home_sessions) * 100 AS conversion_rate_pct
FROM metrics;