/*--------------------------------------------------------------------
  What percentage of all 2021-01-02 page views were PDP-type pages ?
----------------------------------------------------------------------*/
WITH pageviews AS (   -- all page_view events on 2021-01-02 with their URLs
    SELECT
        ep.value:"string_value"::string                     AS page_url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"   e
         ,LATERAL FLATTEN(input => e."EVENT_PARAMS")       ep
    WHERE e."EVENT_NAME" = 'page_view'
      AND e."EVENT_DATE" = '20210102'
      AND ep.value:"key"::string = 'page_location'
      AND ep.value:"string_value" IS NOT NULL
), segs AS (           -- split the URL into path segments
    SELECT
        page_url,
        SPLIT( 
              REGEXP_REPLACE(page_url,'^https?://[^/]+/','') , '/'
        )                                                  AS segments
    FROM pageviews
), classified AS (      -- extract the needed segments to test the rules
    SELECT
        page_url,
        ARRAY_SIZE(segments)                               AS seg_len,
        segments[3]                                        AS seg4,    -- 4th segment (0-based)
        segments[4]                                        AS seg5,    -- 5th segment
        segments[ARRAY_SIZE(segments)-1]                   AS last_seg
    FROM segs
), aggregated AS (      -- count total page views and PDP page views
    SELECT
        COUNT(*)                                                  AS total_views,
        COUNT_IF(                 -- PDP definition
            seg_len >= 5
            AND (
                   REGEXP_LIKE( REPLACE(seg4,'+',' '),
                               '(?i)(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)')
                OR REGEXP_LIKE( REPLACE(seg5,'+',' '),
                               '(?i)(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)')
            )
            AND POSITION('+' IN last_seg) > 0              -- “+” in last segment
        )                                                        AS pdp_views
    FROM classified
)
SELECT
    pdp_views,
    total_views,
    ROUND( (pdp_views * 100.0) / NULLIF(total_views,0), 4 )  AS pdp_percentage
FROM aggregated;