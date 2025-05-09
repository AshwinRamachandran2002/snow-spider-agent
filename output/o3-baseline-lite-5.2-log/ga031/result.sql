/* User‑session conversion rate on 2 Jan 2021 based on page_view events only      */
/* Conversion = sessions that saw BOTH the Home and Checkout‑confirmation pages  */
/*              --------------------------------------------------------------   */
/*            sessions that saw the Home page (at least once in the session)     */

WITH pageviews AS (     -- pull the pieces we need from every 2‑Jan‑2021 page_view
  SELECT
    user_pseudo_id,
    /* GA4 stores the session id inside the event_params array */
    COALESCE(
      (SELECT ep.value.int_value
         FROM UNNEST(event_params) ep
        WHERE ep.key = 'ga_session_id'), 0)                AS ga_session_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title')                         AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
    AND event_date = '20210102'
),

sessions AS (           -- one row per user‑session with page flags
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))        AS session_id,
    -- did the session reach the Home page?
    MAX(page_title = 'Google Online Store')                           AS reached_home,
    -- did the session reach a checkout confirmation / thank‑you page?
    MAX(REGEXP_CONTAINS(page_title,
        r'(?i)(checkout.*confirm|order\s*complete|purchase\s*complete|order\s*received)'))
                                                                   AS reached_checkout
  FROM pageviews
  GROUP BY session_id
)

SELECT
  COUNTIF(reached_home)                                              AS home_sessions,
  COUNTIF(reached_home AND reached_checkout)                         AS converted_sessions,
  ROUND(
        SAFE_DIVIDE(
          COUNTIF(reached_home AND reached_checkout),
          COUNTIF(reached_home)
        ) * 100, 4                                                   -- keep four decimals
  )                                                                  AS conversion_rate_pct
FROM sessions;