/*  Session conversion rate on 2‑Jan‑2021
    ( % of sessions that saw BOTH the Home page and the Checkout‑confirmation page
      ÷ sessions that saw the Home page )
*/
WITH page_views AS (
  SELECT
    user_pseudo_id,
    -- GA4 session identifier
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id')          AS session_id,

    -- Page title in lower‑case for easy matching
    LOWER(
      (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'page_title')
    )                                         AS page_title_lc
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'              -- only page_view events
),

session_flags AS (
  SELECT
    user_pseudo_id,
    session_id,
    -- did the session hit the Home page ?
    MAX(page_title_lc = 'google online store')                                                AS has_home,
    -- did the session hit ANY checkout‑confirmation page ?
    MAX(page_title_lc IN ('checkout confirmation',
                          'order received',
                          'order complete'))                                                  AS has_checkout
  FROM page_views
  WHERE session_id IS NOT NULL
  GROUP BY user_pseudo_id, session_id
)

SELECT
  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(has_home AND has_checkout),     -- numerator : home  + checkout
      COUNTIF(has_home)                       -- denominator : home
    ),
    4
  ) AS session_conversion_rate_percent
FROM session_flags;