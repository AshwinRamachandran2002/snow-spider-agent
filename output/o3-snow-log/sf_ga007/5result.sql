WITH page_views AS (
    SELECT
        "EVENT_DATE",
        page.value:"value":"string_value"::string AS page_url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102",
         LATERAL FLATTEN(input => "EVENT_PARAMS") page
    WHERE page.value:"key"::string = 'page_location'
      AND "EVENT_NAME" = 'page_view'
),
classified AS (
    SELECT
        page_url,
        CASE
            WHEN page_url IS NOT NULL
             AND REGEXP_LIKE(page_url, '\\+')
             AND (
                 REGEXP_LIKE(LOWER(SPLIT_PART(page_url,'/',4)),
                    '(accessories|apparel|brands|campus\\+collection|drinkware|electronics|google\\+redesign|lifestyle|nest|new\\+2015\\+logo|notebooks\\+journals|office|shop\\+by\\+brand|small\\+goods|stationery|wearables)')
                 OR REGEXP_LIKE(LOWER(SPLIT_PART(page_url,'/',5)),
                    '(accessories|apparel|brands|campus\\+collection|drinkware|electronics|google\\+redesign|lifestyle|nest|new\\+2015\\+logo|notebooks\\+journals|office|shop\\+by\\+brand|small\\+goods|stationery|wearables)')
             )
            THEN 1
            ELSE 0
        END AS is_pdp
    FROM page_views
)
SELECT
    ROUND(100.0 * SUM(is_pdp) / COUNT(*), 4) AS "PERCENT_PDP_PAGE_VIEWS"
FROM classified;