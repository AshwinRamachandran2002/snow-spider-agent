/* Session conversion rate on 2‑Jan‑2021 (events_20210102)
   – numerator  : sessions that saw BOTH the Home page and Checkout‑Confirmation page
   – denominator: sessions that saw the Home page
   – scope      : only `page_view` events
*/
WITH page_views AS (      -- 1. keep only needed fields from page_view events
  SELECT
    user_pseudo_id,
    CAST((
          SELECT value.int_value
          FROM UNNEST(event_params)
          WHERE key = 'ga_session_id'
          LIMIT 1
        ) AS INT64)                AS ga_session_id,
    (SELECT value.string_value
     FROM UNNEST(event_params)
     WHERE key = 'page_title'
     LIMIT 1)                      AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

session_flags AS (        -- 2. flag, per session, whether Home / Confirmation was reached
  SELECT
    user_pseudo_id,
    ga_session_id,
    MAX(IF(page_title = 'Google Online Store',       1, 0)) AS has_home,
    MAX(IF(page_title = 'Checkout Confirmation',     1, 0)) AS has_checkout_confirmation
  FROM page_views
  WHERE ga_session_id IS NOT NULL        -- ignore events without a recognised session id
  GROUP BY user_pseudo_id, ga_session_id
)

SELECT
  SAFE_DIVIDE(
      SUM(CASE WHEN has_home = 1 AND has_checkout_confirmation = 1 THEN 1 ELSE 0 END),
      SUM(CASE WHEN has_home = 1 THEN 1 ELSE 0 END)
  ) * 100 AS conversion_rate_percent   -- result expressed as a percentage
FROM session_flags;