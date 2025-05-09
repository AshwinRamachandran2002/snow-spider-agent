WITH pageviews AS (   -- all Jan-02-2021 page-view events together with their URLs
    SELECT
        ep.value:"value":"string_value"::string AS page_url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" e
         ,LATERAL FLATTEN ( INPUT => PARSE_JSON(e."EVENT_PARAMS") ) ep
    WHERE e."EVENT_NAME" = 'page_view'
      AND ep.value:"key"::string = 'page_location'
),

classified AS (        -- split the URL into its path segments
    SELECT
        page_url,
        SPLIT(page_url,'/')                                         AS segments
    FROM pageviews
),

pdp_flag AS (          -- flag each page-view as PDP (=1) or not (=0)
    SELECT
        page_url,
        CASE
            WHEN ARRAY_SIZE(segments) >= 6                                          -- at least 5 “/” segments
             AND segments[ARRAY_SIZE(segments)-1] ILIKE '%+%'                       -- last segment has “+”
             AND (                                                                  -- 4th OR 5th segment is a category
                  REPLACE(UPPER(segments[3]), '+', ' ') IN (                        -- segment index starts at 0
                      'ACCESSORIES','APPAREL','BRANDS','CAMPUS COLLECTION',
                      'DRINKWARE','ELECTRONICS','GOOGLE REDESIGN','LIFESTYLE',
                      'NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS','OFFICE',
                      'SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES'
                  )
               OR REPLACE(UPPER(segments[4]), '+', ' ') IN (
                      'ACCESSORIES','APPAREL','BRANDS','CAMPUS COLLECTION',
                      'DRINKWARE','ELECTRONICS','GOOGLE REDESIGN','LIFESTYLE',
                      'NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS','OFFICE',
                      'SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES'
                  )
             )
            THEN 1 ELSE 0
        END AS is_pdp
    FROM classified
)

SELECT
    ROUND( ( SUM(is_pdp)::FLOAT / COUNT(*) ) * 100 , 4 ) AS "PDP_PAGE_VIEW_PERCENTAGE"
FROM pdp_flag;