/* Home‑to‑Checkout session conversion rate for 02‑Jan‑2021 */
WITH base AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'ga_session_id')                                AS session_id,
    LOWER((SELECT ep.value.string_value
           FROM UNNEST(event_params) AS ep
           WHERE ep.key = 'page_location'))                         AS url,
    LOWER((SELECT ep.value.string_value
           FROM UNNEST(event_params) AS ep
           WHERE ep.key = 'page_title'))                            AS title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
session_flags AS (
  SELECT
    user_pseudo_id,
    session_id,
    MAX(
      url  IN ('https://googlemerchandisestore.com/',
               'https://shop.googlemerchandisestore.com/',
               'https://shop.googlemerchandisestore.com/store.html')
      OR title IN ('home', 'google online store')
    )                                                              AS hit_home,
    MAX(
      url   LIKE '%checkout%' OR url   LIKE '%confirmation%'
      OR title LIKE '%checkout%' OR title LIKE '%confirmation%'
    )                                                              AS hit_checkout
  FROM base
  GROUP BY user_pseudo_id, session_id
)
SELECT
  COUNTIF(hit_home)                                                AS home_sessions,
  COUNTIF(hit_home AND hit_checkout)                               AS converted_sessions,
  ROUND(100 * COUNTIF(hit_home AND hit_checkout)
           / NULLIF(COUNTIF(hit_home), 0), 2)                      AS conversion_rate_pct
FROM session_flags;