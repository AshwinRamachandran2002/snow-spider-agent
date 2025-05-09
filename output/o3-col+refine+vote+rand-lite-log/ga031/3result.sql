-- User-session conversion rate on 2-Jan-2021 (page_view events only)
WITH base AS (           -- pull useful fields once
  SELECT
    user_pseudo_id,
    CAST(
      (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id') AS INT64
    )                                         AS ga_session_id,
    LOWER(
      (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_title')
    )                                         AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

home AS (                -- sessions that landed on the Home page
  SELECT DISTINCT user_pseudo_id, ga_session_id
  FROM base
  WHERE page_title LIKE '%online store%'               -- “Google Online Store …”
     OR page_title = 'home'                            -- explicit “Home” title
),

checkout_confirm AS (    -- sessions that reached Checkout Confirmation page
  SELECT DISTINCT user_pseudo_id, ga_session_id
  FROM base
  WHERE page_title LIKE '%checkout confirmation%'
),

both AS (                -- sessions that did both actions
  SELECT h.user_pseudo_id, h.ga_session_id
  FROM home h
  JOIN checkout_confirm c
  USING (user_pseudo_id, ga_session_id)
)

SELECT
  COUNT(DISTINCT both.ga_session_id)                                          AS both_sessions,
  COUNT(DISTINCT home.ga_session_id)                                          AS home_sessions,
  SAFE_DIVIDE(COUNT(DISTINCT both.ga_session_id),
              COUNT(DISTINCT home.ga_session_id)) * 100                       AS conversion_rate_percent
FROM home
LEFT JOIN both USING (user_pseudo_id, ga_session_id);