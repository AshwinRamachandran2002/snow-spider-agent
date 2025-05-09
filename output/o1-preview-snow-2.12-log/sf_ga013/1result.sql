WITH PageViews AS (
    SELECT
        t."EVENT_TIMESTAMP",
        page_title.value:"value":"string_value"::STRING AS "PAGE_TITLE",
        page_location.value:"value":"string_value"::STRING AS "PAGE_URL"
    FROM
        GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" t,
        LATERAL FLATTEN(input => t."EVENT_PARAMS") page_title,
        LATERAL FLATTEN(input => t."EVENT_PARAMS") page_location
    WHERE
        t."USER_PSEUDO_ID" = '1402138.5184246691'
        AND t."EVENT_NAME" = 'page_view'
        AND page_title.value:"key"::STRING = 'page_title'
        AND page_location.value:"key"::STRING = 'page_location'
),
CategoryNames AS (
    SELECT LOWER(REPLACE('Accessories', ' ', '+')) AS CategoryName UNION ALL
    SELECT LOWER(REPLACE('Apparel', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Brands', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Campus Collection', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Drinkware', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Electronics', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Google Redesign', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Lifestyle', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Nest', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('New 2015 Logo', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Notebooks Journals', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Office', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Shop by Brand', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Small Goods', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Stationery', ' ', '+')) UNION ALL
    SELECT LOWER(REPLACE('Wearables', ' ', '+'))
),
ProcessedPages AS (
    SELECT
        "PAGE_TITLE" AS "Page_Name",
        CASE
            WHEN NUM_SEGMENTS >= 5
             AND POSITION('+' IN COALESCE(SEGMENT_4, '')) = 0
             AND POSITION('+' IN COALESCE(SEGMENT_5, '')) = 0
             AND (
                 LOWER(SEGMENT_4) IN (SELECT CategoryName FROM CategoryNames)
                 OR LOWER(SEGMENT_5) IN (SELECT CategoryName FROM CategoryNames)
             )
             THEN 'PLP'
            WHEN NUM_SEGMENTS >= 5
             AND POSITION('+' IN COALESCE(LAST_SEGMENT, '')) > 0
             AND (
                 LOWER(SEGMENT_4) IN (SELECT CategoryName FROM CategoryNames)
                 OR LOWER(SEGMENT_5) IN (SELECT CategoryName FROM CategoryNames)
             )
             THEN 'PDP'
            ELSE 'Other'
        END AS "Page_Type"
    FROM
    (
        SELECT
            "EVENT_TIMESTAMP",
            "PAGE_TITLE",
            "PAGE_URL",
            SPLIT(REGEXP_REPLACE("PAGE_URL", '^https?://[^/]+', ''), '/') AS URL_SEGMENTS,
            ARRAY_SIZE(URL_SEGMENTS) AS NUM_SEGMENTS,
            GET(URL_SEGMENTS, 3) AS SEGMENT_4,
            GET(URL_SEGMENTS, 4) AS SEGMENT_5,
            CASE WHEN ARRAY_SIZE(URL_SEGMENTS) > 0 THEN GET(URL_SEGMENTS, ARRAY_SIZE(URL_SEGMENTS) -1) ELSE NULL END AS LAST_SEGMENT
        FROM
            PageViews
    )
)
SELECT DISTINCT
    "Page_Name",
    "Page_Type"
FROM
    ProcessedPages
ORDER BY
    "Page_Name";