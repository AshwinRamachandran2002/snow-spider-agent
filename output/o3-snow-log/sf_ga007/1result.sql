WITH raw AS (   -- all page-views on 2-Jan-2021 with their URL
    SELECT
        ep.value:"value":"string_value"::string AS url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" ev ,
         LATERAL FLATTEN ( INPUT => PARSE_JSON(ev."EVENT_PARAMS") ) ep
    WHERE ev."EVENT_NAME" = 'page_view'
      AND ep.value:"key"::string = 'page_location'
      AND ep.value:"value":"string_value" IS NOT NULL
),
split_url AS (  -- split the URL into path segments
    SELECT
        url,
        SPLIT(url,'/')                         AS segments ,
        ARRAY_SIZE(SPLIT(url,'/'))             AS seg_cnt
    FROM raw
),
classified AS ( -- identify PDP URLs
    SELECT
        url ,
        CASE
            WHEN seg_cnt >= 5                                                      -- at least 5 segments
                 AND POSITION('+' IN segments[seg_cnt-1]) > 0                      -- last segment has '+'
                 AND (
                       REGEXP_LIKE(
                           UPPER(REPLACE(segments[3], '+', ' ')),
                           '^(ACCESSORIES|APPAREL|BRANDS|CAMPUS COLLECTION|DRINKWARE|ELECTRONICS|GOOGLE REDESIGN|LIFESTYLE|NEST|NEW 2015 LOGO|NOTEBOOKS JOURNALS|OFFICE|SHOP BY BRAND|SMALL GOODS|STATIONERY|WEARABLES)$'
                       )
                       OR
                       REGEXP_LIKE(
                           UPPER(REPLACE(segments[4], '+', ' ')),
                           '^(ACCESSORIES|APPAREL|BRANDS|CAMPUS COLLECTION|DRINKWARE|ELECTRONICS|GOOGLE REDESIGN|LIFESTYLE|NEST|NEW 2015 LOGO|NOTEBOOKS JOURNALS|OFFICE|SHOP BY BRAND|SMALL GOODS|STATIONERY|WEARABLES)$'
                       )
                 )
            THEN 1 ELSE 0
        END AS is_pdp
    FROM split_url
)
SELECT
    ROUND(100.0 * SUM(is_pdp) / COUNT(*), 4) AS "PERCENT_PDP_PAGE_VIEWS"
FROM classified;