/*  Home-to-Checkout-confirmation conversion rate – 2-Jan-2021  */
WITH page_hits AS (   -- pull page_title and GA4 session id from page_view rows
    SELECT
        f_title.value:"value":"string_value"::STRING  AS page_title ,
        f_ses.value:"value":"int_value"::NUMBER       AS ga_session_id
    FROM  GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  t
          ,LATERAL FLATTEN ( INPUT => t."EVENT_PARAMS") f_title
          ,LATERAL FLATTEN ( INPUT => t."EVENT_PARAMS") f_ses
    WHERE t."EVENT_NAME" = 'page_view'
      AND f_title.value:"key"::STRING = 'page_title'
      AND f_ses.value:"key" ::STRING = 'ga_session_id'
),
session_flags AS (     -- flag sessions that hit Home and Confirmation pages
    SELECT
        ga_session_id ,
        MAX( CASE WHEN LOWER(page_title) = 'home'              THEN 1 END) AS hit_home ,
        MAX( CASE WHEN page_title ILIKE '%confirm%'            THEN 1 END) AS hit_confirmation
    FROM page_hits
    GROUP BY ga_session_id
),
agg AS (                -- aggregate the flagged sessions
    SELECT
        COUNT( DISTINCT CASE WHEN hit_home = 1                   THEN ga_session_id END) AS sessions_home ,
        COUNT( DISTINCT CASE WHEN hit_home = 1
                               AND hit_confirmation = 1          THEN ga_session_id END) AS sessions_both
    FROM session_flags
)
SELECT
    sessions_home ,
    sessions_both ,
    100.0 * sessions_both / NULLIF(sessions_home,0)  AS conversion_rate_pct
FROM agg;