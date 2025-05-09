-- User-session conversion rate for 2-Jan-2021 (Home → Checkout Confirmation)
WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id')                     AS ga_session_id,
    MAX(CASE
          WHEN ep.key = 'page_location'
               AND ep.value.string_value = 'https://googlemerchandisestore.com/' THEN 1
          ELSE 0
        END)                                               AS saw_home,
    MAX(CASE
          WHEN ep.key = 'page_title'
               AND LOWER(ep.value.string_value) LIKE '%checkout%confirmation%' THEN 1
          ELSE 0
        END)                                               AS saw_checkout
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  CROSS JOIN UNNEST(event_params) ep
  WHERE event_name = 'page_view'
  GROUP BY user_pseudo_id, ga_session_id
)

SELECT
  COUNTIF(saw_home = 1 AND saw_checkout = 1)                                    AS sessions_home_and_checkout,
  COUNTIF(saw_home = 1)                                                         AS sessions_with_home,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(saw_home = 1 AND saw_checkout = 1),
      COUNTIF(saw_home = 1)
    ) * 100,
    4
  )                                                                             AS conversion_rate_percent
FROM sessions;