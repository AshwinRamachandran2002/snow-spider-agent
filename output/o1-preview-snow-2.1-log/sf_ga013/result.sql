SELECT
    t."PAGE_LOCATION" AS "Page_Name",
    CASE
        WHEN ARRAY_SIZE(t.segments) >= 6
            AND REGEXP_LIKE(t.segments[ARRAY_SIZE(t.segments)-1], '\\+')
            AND (
                UPPER(REPLACE(t.segments[3], '+', ' ')) IN (
                    'ACCESSORIES', 'APPAREL', 'BRANDS', 'CAMPUS COLLECTION', 'DRINKWARE',
                    'ELECTRONICS', 'GOOGLE REDESIGN', 'LIFESTYLE', 'NEST', 'NEW 2015 LOGO',
                    'NOTEBOOKS JOURNALS', 'OFFICE', 'SHOP BY BRAND', 'SMALL GOODS',
                    'STATIONERY', 'WEARABLES'
                )
                OR
                UPPER(REPLACE(t.segments[4], '+', ' ')) IN (
                    'ACCESSORIES', 'APPAREL', 'BRANDS', 'CAMPUS COLLECTION', 'DRINKWARE',
                    'ELECTRONICS', 'GOOGLE REDESIGN', 'LIFESTYLE', 'NEST', 'NEW 2015 LOGO',
                    'NOTEBOOKS JOURNALS', 'OFFICE', 'SHOP BY BRAND', 'SMALL GOODS',
                    'STATIONERY', 'WEARABLES'
                )
            )
            THEN 'PDP'
        WHEN ARRAY_SIZE(t.segments) >= 6
            AND NOT REGEXP_LIKE(t.segments[3], '\\+')
            AND NOT REGEXP_LIKE(t.segments[4], '\\+')
            AND (
                UPPER(REPLACE(t.segments[3], '+', ' ')) IN (
                    'ACCESSORIES', 'APPAREL', 'BRANDS', 'CAMPUS COLLECTION', 'DRINKWARE',
                    'ELECTRONICS', 'GOOGLE REDESIGN', 'LIFESTYLE', 'NEST', 'NEW 2015 LOGO',
                    'NOTEBOOKS JOURNALS', 'OFFICE', 'SHOP BY BRAND', 'SMALL GOODS',
                    'STATIONERY', 'WEARABLES'
                )
                OR
                UPPER(REPLACE(t.segments[4], '+', ' ')) IN (
                    'ACCESSORIES', 'APPAREL', 'BRANDS', 'CAMPUS COLLECTION', 'DRINKWARE',
                    'ELECTRONICS', 'GOOGLE REDESIGN', 'LIFESTYLE', 'NEST', 'NEW 2015 LOGO',
                    'NOTEBOOKS JOURNALS', 'OFFICE', 'SHOP BY BRAND', 'SMALL GOODS',
                    'STATIONERY', 'WEARABLES'
                )
            )
            THEN 'PLP'
        ELSE 'Other'
    END AS "Page_Type"
FROM (
    SELECT
        ep.value:"value":"string_value"::STRING AS "PAGE_LOCATION",
        SPLIT(ep.value:"value":"string_value"::STRING, '/') AS segments
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" e,
         LATERAL FLATTEN(input => e."EVENT_PARAMS") ep
    WHERE e."USER_PSEUDO_ID" = '1402138.5184246691'
      AND e."EVENT_NAME" = 'page_view'
      AND ep.value:"key"::STRING = 'page_location'
) t;