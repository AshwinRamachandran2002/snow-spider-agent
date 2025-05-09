/*  Pages visited by user 1402138.5184246691 on 2-Jan-2021
    – together with a PDP / PLP classification                                        */

WITH all_events AS (      -- one row per event
    SELECT
        MAX(CASE WHEN f.value:"key"::STRING = 'page_title'
                 THEN f.value:"value":"string_value"::STRING END)      AS page_title ,
        MAX(CASE WHEN f.value:"key"::STRING = 'page_location'
                 THEN f.value:"value":"string_value"::STRING END)      AS page_location
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  t,
         LATERAL FLATTEN ( INPUT => t."EVENT_PARAMS" )          f
    WHERE t."EVENT_DATE"   = '20210102'
      AND t."USER_PSEUDO_ID" = '1402138.5184246691'
    GROUP BY t."EVENT_TIMESTAMP"
),

classified AS (           -- split the URL into the relevant path segments
    SELECT DISTINCT
           page_title,
           page_location,
           SPLIT_PART(page_location , '/' , 4) AS seg4 ,
           SPLIT_PART(page_location , '/' , 5) AS seg5 ,
           SPLIT_PART(page_location , '/' , 6) AS seg6
    FROM   all_events
    WHERE  page_location IS NOT NULL
),

final AS (                -- apply refined PDP / PLP rules
    SELECT
        page_title,
        page_location,
        CASE
            /* ---------- PDP ---------- */
            WHEN seg6 LIKE '%+%' AND (
                   UPPER(REPLACE(seg4,'+',' ')) IN ('ACCESSORIES','APPAREL','BRANDS',
                       'CAMPUS COLLECTION','DRINKWARE','ELECTRONICS','GOOGLE REDESIGN',
                       'LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS','OFFICE',
                       'SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES')
                OR UPPER(REPLACE(seg5,'+',' ')) IN ('ACCESSORIES','APPAREL','BRANDS',
                       'CAMPUS COLLECTION','DRINKWARE','ELECTRONICS','GOOGLE REDESIGN',
                       'LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS','OFFICE',
                       'SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES')
            ) THEN 'PDP'

            /* ---------- PLP ---------- */
            WHEN (
                   UPPER(REPLACE(seg4,'+',' ')) IN ('ACCESSORIES','APPAREL','BRANDS',
                       'CAMPUS COLLECTION','DRINKWARE','ELECTRONICS','GOOGLE REDESIGN',
                       'LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS','OFFICE',
                       'SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES')
                OR UPPER(REPLACE(seg5,'+',' ')) IN ('ACCESSORIES','APPAREL','BRANDS',
                       'CAMPUS COLLECTION','DRINKWARE','ELECTRONICS','GOOGLE REDESIGN',
                       'LIFESTYLE','NEST','NEW 2015 LOGO','NOTEBOOKS JOURNALS','OFFICE',
                       'SHOP BY BRAND','SMALL GOODS','STATIONERY','WEARABLES')
            )
            AND seg4 NOT LIKE '%+%' AND seg5 NOT LIKE '%+%'
            THEN 'PLP'

            /* ---------- everything else ---------- */
            ELSE 'OTHER'
        END AS page_type
    FROM classified
)

SELECT
       page_title      AS "PAGE_NAME",
       page_type       AS "PAGE_CATEGORY",
       page_location   AS "URL"
FROM   final
ORDER  BY page_location;