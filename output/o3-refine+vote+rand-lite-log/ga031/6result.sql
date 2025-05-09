WITH page_views AS (
  -- keep only page_view events from 2‑Jan‑2021 and pull the fields we need
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1)                      AS ga_session_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1)                      AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1)                      AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

session_flags AS (
  -- flag, for every session, whether it saw the Home page and/or the Checkout‑confirmation page
  SELECT
    user_pseudo_id,
    ga_session_id,
    MAX( CASE
            -- Home page: root URL or canonical home‑page title
            WHEN LOWER(page_title) = 'google online store'
                 OR REGEXP_CONTAINS(page_location,
                     r'^https://(shop\.)?googlemerchandisestore\.com/?$')
            THEN 1 ELSE 0 END ) AS saw_home,

    MAX( CASE
            -- Checkout confirmation page: url/title contains confirmation / complete / thankyou
            WHEN REGEXP_CONTAINS(LOWER(page_title),
                     r'confirmation|complete|thank you|order received')
                 OR REGEXP_CONTAINS(LOWER(page_location),
                     r'confirmation|complete|thankyou')
            THEN 1 ELSE 0 END ) AS saw_checkout_confirmation
  FROM page_views
  GROUP BY user_pseudo_id, ga_session_id
),

agg AS (
  -- sessions that landed on Home vs. those that also reached Checkout confirmation
  SELECT
    COUNTIF(saw_home = 1)                                          AS sessions_with_home,
    COUNTIF(saw_home = 1 AND saw_checkout_confirmation = 1)        AS sessions_converted
  FROM session_flags
)

SELECT
  sessions_with_home,
  sessions_converted,
  ROUND( SAFE_DIVIDE(sessions_converted, sessions_with_home) * 100 , 4) AS conversion_rate_percent
FROM agg;