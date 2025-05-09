WITH page_views AS (       -- 1. collect all page-views of 02-Jan-2021 and pull their URLs
    SELECT
        ev."EVENT_TIMESTAMP",
        ep.value:"string_value"::string        AS url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  ev
         ,LATERAL FLATTEN ( input => ev."EVENT_PARAMS") ep
    WHERE ev."EVENT_NAME" = 'page_view'
      AND ep.value:"key"::string = 'page_location'
),
parsed AS (                -- 2. split the URL into path-segments after the domain
    SELECT
        url,
        SPLIT(
              REGEXP_REPLACE(url, '^https?://[^/]+/?', ''),    -- keep only the path
              '/')                                            AS segments
    FROM page_views
),
classified AS (            -- 3. apply PDP rules
    SELECT
        url,
        CASE
            WHEN ARRAY_SIZE(segments) >= 5                                             -- at least 5 segments
             AND POSITION('+' IN segments[ARRAY_SIZE(segments)-1]) > 0                 -- last segment has '+'
             AND (
                    LOWER(REPLACE(segments[3], '+',' ')) RLIKE
                       '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                 OR LOWER(REPLACE(segments[4], '+',' ')) RLIKE
                       '(accessories|apparel|brands|campus collection|drinkware|electronics|google redesign|lifestyle|nest|new 2015 logo|notebooks journals|office|shop by brand|small goods|stationery|wearables)'
                 )
            THEN 1 ELSE 0
        END                                                    AS is_pdp
    FROM parsed
),
agg AS (                   -- 4. aggregate counts
    SELECT
        COUNT(*)                             AS total_page_views,
        SUM(is_pdp)                          AS pdp_page_views
    FROM classified
)
SELECT
    ROUND(100.0 * pdp_page_views / NULLIF(total_page_views,0), 4) AS pdp_page_view_percentage
FROM agg;