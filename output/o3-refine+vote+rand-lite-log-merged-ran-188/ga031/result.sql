WITH page_views AS (
  SELECT
    user_pseudo_id,
    COALESCE(                                   -- session identifier
      (SELECT value.int_value
       FROM UNNEST(event_params)
       WHERE key = 'ga_session_id'),
      -1)                           AS session_id,
    (SELECT value.string_value
     FROM UNNEST(event_params)
     WHERE key = 'page_title')      AS page_title,
    (SELECT value.string_value
     FROM UNNEST(event_params)
     WHERE key = 'page_location')   AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
session_flags AS (                  -- mark required pages per session
  SELECT
    user_pseudo_id,
    session_id,
    LOGICAL_OR(                      -- TRUE if Home was viewed in the session
      page_title = 'Google Online Store'
      OR REGEXP_CONTAINS(page_location,
            r'^https?://(www\.)?googlemerchandisestore\.com/?$')
    ) AS has_home,
    LOGICAL_OR(                      -- TRUE if Checkout‑Confirmation was viewed
      (REGEXP_CONTAINS(LOWER(page_location), r'/checkout')
       AND REGEXP_CONTAINS(LOWER(page_location), r'confirmation'))
      OR REGEXP_CONTAINS(LOWER(page_title), r'checkout.*confirmation')
    ) AS has_confirmation
  FROM page_views
  GROUP BY user_pseudo_id, session_id
),
totals AS (
  SELECT
    COUNTIF(has_home)                              AS sessions_with_home,
    COUNTIF(has_home AND has_confirmation)         AS sessions_converted
  FROM session_flags
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(sessions_converted, sessions_with_home),
    4
  ) AS session_conversion_rate_percent
FROM totals;