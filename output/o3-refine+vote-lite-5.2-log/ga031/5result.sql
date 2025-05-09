-- User‑session conversion rate on 2‑Jan‑2021
--  (Sessions that saw BOTH Home and Checkout‑Confirmation pages)
/*  Definition of a “session” = combination of user_pseudo_id + ga_session_id
    Home page          : exact root URL of the store
                         https://googlemerchandisestore.com/   or
                         https://shop.googlemerchandisestore.com/
    Confirmation page  : any page whose URL or title contains the words
                         checkout AND (confirm|thank|complete)  – case‑insensitive
*/

WITH pageviews AS (   -- pull only page_view events for the day
  SELECT
    user_pseudo_id,
    -- ga_session_id is stored as INT64 in event_params
    ( SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')                     AS session_id,

    -- page_location and page_title are stored as STRINGs
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')                     AS page_location,

    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title')                        AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),

session_flags AS (     -- flag whether each session hit Home / Confirmation pages
  SELECT
    user_pseudo_id,
    session_id,
    MAX( CASE
            WHEN REGEXP_CONTAINS(
                   IFNULL(page_location ,''), r'^https://(shop\.)?googlemerchandisestore\.com/?$')
            THEN 1 ELSE 0 END)                                        AS hit_home,

    MAX( CASE
            WHEN REGEXP_CONTAINS( IFNULL(page_location,''), r'(?i)checkout')
                 AND REGEXP_CONTAINS( IFNULL(page_location,''), r'(?i)(confirm|thank|complete)')
            THEN 1
            WHEN REGEXP_CONTAINS( IFNULL(page_title ,''), r'(?i)(checkout|order|purchase).*(confirm|complete|thank)')
            THEN 1
            ELSE 0
         END)                                                         AS hit_confirmation
  FROM pageviews
  GROUP BY user_pseudo_id, session_id
)

SELECT
  ROUND( 100 * SAFE_DIVIDE(
           SUM( CASE WHEN hit_home = 1 AND hit_confirmation = 1 THEN 1 ELSE 0 END ),
           SUM( CASE WHEN hit_home = 1 THEN 1 ELSE 0 END )
         ),4) AS session_conversion_rate_percent
FROM session_flags;