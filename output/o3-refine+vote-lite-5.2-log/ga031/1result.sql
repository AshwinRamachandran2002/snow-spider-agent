/*  Session conversion rate on 2021‑01‑02
    – “conversion” means a session that reached BOTH the Home page and the Checkout‑confirmation page
    – denominator = all sessions that reached the Home page
*/

WITH page_views AS (
  SELECT
    user_pseudo_id,
    /* GA4 session identifier stored in event_params → ga_session_id */
    ( SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
      LIMIT 1
    )                                                AS session_id,

    LOWER(
      ( SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'page_location'
        LIMIT 1
      )
    )                                                AS page_location,

    LOWER(
      ( SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'page_title'
        LIMIT 1
      )
    )                                                AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

labeled AS (
  /* flag each row as “Home” or “Checkout confirmation” */
  SELECT
    user_pseudo_id,
    session_id,

    /* Home page: root URL or canonical home titles            */
    CASE
      WHEN page_location IN ('https://googlemerchandisestore.com/',
                             'https://shop.googlemerchandisestore.com/')
           OR page_title IN ('google online store',
                             'shop | google merchandise store')
      THEN 1 ELSE 0
    END                                            AS is_home,

    /* Confirmation page: title or URL containing “confirmation” */
    CASE
      WHEN page_title     LIKE '%confirmation%'
        OR page_location  LIKE '%/checkout%' AND page_location LIKE '%confirm%'
      THEN 1 ELSE 0
    END                                            AS is_confirmation
  FROM page_views
  WHERE session_id IS NOT NULL                       -- keep only sessions we can recognise
),

sessions AS (
  /* roll‑up to one row per (user, session) */
  SELECT
    user_pseudo_id,
    session_id,
    MAX(is_home)          AS has_home,
    MAX(is_confirmation)  AS has_confirmation
  FROM labeled
  GROUP BY user_pseudo_id, session_id
  HAVING MAX(is_home) = 1                            -- keep only sessions that hit Home
)

SELECT
  ROUND( 100 * SUM(CASE WHEN has_confirmation = 1 THEN 1 ELSE 0 END)
/         COUNT(*),                                  /* sessions that hit Home */
        4 )            AS session_conversion_rate_pct
FROM sessions;