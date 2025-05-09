WITH page_views AS (
    SELECT
        ep.value:"value":"string_value"::string AS page_url
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" ev,
         LATERAL FLATTEN(INPUT => ev."EVENT_PARAMS") ep
    WHERE ev."EVENT_NAME" = 'page_view'
      AND ep.value:"key"::string = 'page_location'
),  
classified AS (
    SELECT
        page_url,
        SPLIT_PART(page_url, '/', 4) AS segment4,
        SPLIT_PART(page_url, '/', 5) AS segment5,
        SPLIT_PART(page_url, '/', -1) AS last_segment,
        CASE
            WHEN last_segment LIKE '%+%'
             AND (
                    REGEXP_LIKE(segment4,
                                '(Accessories|Apparel|Brands|Campus\\+Collection|Drinkware|Electronics|Google\\+Redesign|Lifestyle|Nest|New\\+2015\\+Logo|Notebooks\\+Journals|Office|Shop\\+by\\+Brand|Small\\+Goods|Stationery|Wearables)',
                                'i')
                 OR REGEXP_LIKE(segment5,
                                '(Accessories|Apparel|Brands|Campus\\+Collection|Drinkware|Electronics|Google\\+Redesign|Lifestyle|Nest|New\\+2015\\+Logo|Notebooks\\+Journals|Office|Shop\\+by\\+Brand|Small\\+Goods|Stationery|Wearables)',
                                'i')
                 )
            THEN 1 ELSE 0
        END AS is_pdp
    FROM page_views
)
SELECT
    ROUND(100.0 * SUM(is_pdp) / COUNT(*), 4) AS "PCT_PDP_PAGE_VIEWS"
FROM classified;