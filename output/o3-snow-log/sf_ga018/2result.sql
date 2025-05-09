/*  PLP → PDP transition rate for 02-Jan-2021 (page_view events only)  */
WITH events AS (      -- pull URL, session-id, timestamp for every page_view
    SELECT
        sid.value:"value":"int_value"::NUMBER    AS ga_session_id,
        url.value:"value":"string_value"::STRING AS page_location,
        t.EVENT_TIMESTAMP                        AS event_timestamp
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210102 t
         , LATERAL FLATTEN( INPUT => t.EVENT_PARAMS ) url
         , LATERAL FLATTEN( INPUT => t.EVENT_PARAMS ) sid
    WHERE t.EVENT_NAME            = 'page_view'
      AND url.value:"key"::STRING = 'page_location'
      AND sid.value:"key"::STRING = 'ga_session_id'
),

page_views AS (      -- classify each view as PLP / PDP / OTHER
    SELECT
        ga_session_id,
        page_location,
        event_timestamp,
        CASE
            WHEN page_location IS NOT NULL
                 AND ARRAY_SIZE( SPLIT(page_location,'/') ) >= 5
                 AND POSITION('+', SPLIT_PART(page_location,'/',-1)) = 0
                 AND REGEXP_LIKE(
                        page_location,
                        '(Accessories|Apparel|Brands|Campus Collection|Drinkware|Electronics|Google Redesign|Lifestyle|Nest|New 2015 Logo|Notebooks Journals|Office|Shop by Brand|Small Goods|Stationery|Wearables)'
                     )
                 THEN 'PLP'
            WHEN page_location IS NOT NULL
                 AND ARRAY_SIZE( SPLIT(page_location,'/') ) >= 5
                 AND POSITION('+', SPLIT_PART(page_location,'/',-1)) > 0
                 AND REGEXP_LIKE(
                        page_location,
                        '(Accessories|Apparel|Brands|Campus Collection|Drinkware|Electronics|Google Redesign|Lifestyle|Nest|New 2015 Logo|Notebooks Journals|Office|Shop by Brand|Small Goods|Stationery|Wearables)'
                     )
                 THEN 'PDP'
            ELSE 'OTHER'
        END AS page_type
    FROM events
),

plp_views AS (       -- every PLP page_view
    SELECT *
    FROM   page_views
    WHERE  page_type = 'PLP'
),

plp_followed_by_pdp AS (   -- PLP views that are followed by a PDP in the same session
    SELECT p.*
    FROM   plp_views p
    WHERE  EXISTS (
              SELECT 1
              FROM   page_views pdp
              WHERE  pdp.ga_session_id   = p.ga_session_id
                AND  pdp.page_type       = 'PDP'
                AND  pdp.event_timestamp > p.event_timestamp
          )
)

SELECT
    (SELECT COUNT(*) FROM plp_views)           AS total_plp_views,
    (SELECT COUNT(*) FROM plp_followed_by_pdp) AS plp_views_leading_to_pdp,
    CASE
        WHEN (SELECT COUNT(*) FROM plp_views) > 0
        THEN ROUND(
                 (SELECT COUNT(*) FROM plp_followed_by_pdp) * 100.0
                 / (SELECT COUNT(*) FROM plp_views),
                 2
             )
        ELSE NULL
    END                                        AS plp_to_pdp_percentage;