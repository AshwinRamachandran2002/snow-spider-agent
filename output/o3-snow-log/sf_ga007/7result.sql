/* Percentage of 2-Jan-2021 “page_view” events that are PDPs */
WITH page_views AS (                           -- pull URLs of all page-view events
    SELECT
        f.value:"value":"string_value"::string AS page_url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" e,
         LATERAL FLATTEN (INPUT => e."EVENT_PARAMS") f
    WHERE e."EVENT_NAME" = 'page_view'
      AND e."EVENT_DATE" = '20210102'
      AND f.value:"key"::string = 'page_location'
),                                             
segmented AS (                                 -- split the URL path into segments
    SELECT
        page_url,
        SPLIT(                                   
            LTRIM( (PARSE_URL(page_url):path)::string, '/' ),
            '/'
        ) AS segs
    FROM page_views
),
classified AS (                                -- identify PDPs
    SELECT
        CASE
            WHEN ARRAY_SIZE(segs) >= 5
                 AND POSITION('+', segs[ARRAY_SIZE(segs)-1]::string) > 0
                 AND (
                        REGEXP_LIKE(segs[3]::string,
                                    '(?i)^(Accessories|Apparel|Brands|Campus Collection|Drinkware|Electronics|Google Redesign|Lifestyle|Nest|New 2015 Logo|Notebooks Journals|Office|Shop by Brand|Small Goods|Stationery|Wearables)$')
                     OR REGEXP_LIKE(COALESCE(segs[4]::string,''),
                                    '(?i)^(Accessories|Apparel|Brands|Campus Collection|Drinkware|Electronics|Google Redesign|Lifestyle|Nest|New 2015 Logo|Notebooks Journals|Office|Shop by Brand|Small Goods|Stationery|Wearables)$')
                 )
            THEN 1 ELSE 0
        END AS is_pdp
    FROM segmented
)
SELECT
    ROUND(100.0 * SUM(is_pdp)::FLOAT / COUNT(*), 4) AS pct_pdp_pageviews
FROM classified;