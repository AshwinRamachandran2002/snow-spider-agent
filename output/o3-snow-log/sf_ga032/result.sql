WITH raw AS (          -- 1. page_view rows for the user on 2021-01-28
    SELECT
        e."EVENT_TIMESTAMP",
        MAX(
            CASE WHEN f.value:key::string = 'page_location'
                 THEN f.value:value:string_value::string END
        ) AS page_location,
        MAX(
            CASE WHEN f.value:key::string = 'page_title'
                 THEN f.value:value:string_value::string END
        ) AS page_title
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210128"  e,
         LATERAL FLATTEN (INPUT => PARSE_JSON(e."EVENT_PARAMS")) f
    WHERE e."EVENT_NAME"     = 'page_view'
      AND e."USER_PSEUDO_ID" = '1362228.4966015575'
    GROUP BY e."EVENT_TIMESTAMP"
),
classified AS (         -- 2. convert each URL into PLP / PDP / title label
    SELECT
        "EVENT_TIMESTAMP",
        page_title,
        page_location,
        CASE
            WHEN page_location IS NOT NULL
                 AND REGEXP_LIKE(page_location,'/[^/]*\\+[^/]*$','i')
                 AND REGEXP_LIKE(page_location,
                                 '/(Accessories|Apparel|Brands|Campus\\+Collection|Drinkware|Electronics|Google\\+Redesign|Lifestyle|Nest|New\\+2015\\+Logo|Notebooks\\+Journals|Office|Shop\\+by\\+Brand|Small\\+Goods|Stationery|Wearables)/',
                                 'i')
            THEN 'PDP'
            WHEN page_location IS NOT NULL
                 AND NOT REGEXP_LIKE(page_location,'/[^/]*\\+[^/]*$','i')
                 AND REGEXP_LIKE(page_location,
                                 '/(Accessories|Apparel|Brands|Campus\\+Collection|Drinkware|Electronics|Google\\+Redesign|Lifestyle|Nest|New\\+2015\\+Logo|Notebooks\\+Journals|Office|Shop\\+by\\+Brand|Small\\+Goods|Stationery|Wearables)/',
                                 'i')
            THEN 'PLP'
            ELSE page_title
        END AS page_label
    FROM raw
),
dedup AS (              -- 3. remove consecutive duplicates
    SELECT *
    FROM (
        SELECT
            "EVENT_TIMESTAMP",
            page_label,
            LAG(page_label) OVER (ORDER BY "EVENT_TIMESTAMP") AS prev_label
        FROM classified
    )
    WHERE page_label IS NOT NULL
      AND (prev_label IS NULL OR prev_label <> page_label)
)
-- 4. build navigation flow
SELECT
    LISTAGG(page_label, ' >> ') WITHIN GROUP (ORDER BY "EVENT_TIMESTAMP") AS navigation_flow
FROM dedup;