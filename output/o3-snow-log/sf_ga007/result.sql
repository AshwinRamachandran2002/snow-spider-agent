/*------------------------------------------------------------
  % of PAGE_VIEW events on 02-Jan-2021 that were PDP pages
  ‑ PDP rules (see prompt):
      • ≥5 URL path segments
      • last segment contains “+”
      • 4th OR 5th segment is one of the allowed categories
------------------------------------------------------------*/
WITH page_views AS (
    /* pull every PAGE_VIEW together with its page_location URL */
    SELECT
        /* strip protocol & domain so we only keep the path portion */
        REGEXP_REPLACE(
            f.value:"value":"string_value"::string,
            '^https?://[^/]+/'
        )                                    AS path_only
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  e
         , LATERAL FLATTEN(input => e."EVENT_PARAMS")           f
    WHERE e."EVENT_NAME" = 'page_view'
      AND f.value:"key"::string = 'page_location'
),
classified AS (
    /* split the path into segments and decide if it is a PDP */
    SELECT
        path_only,
        SPLIT(path_only, '/')                                         AS segments
    FROM page_views
),
metrics AS (
    SELECT
        COUNT(*)                                                      AS total_views,
        SUM(
            CASE
                WHEN ARRAY_SIZE(segments) >= 5
                     AND segments[ARRAY_SIZE(segments)-1]::string LIKE '%+%'
                     AND (
                          COALESCE(segments[3]::string,'') RLIKE '(?i)Accessories|Apparel|Brands|Campus\\+Collection|Drinkware|Electronics|Google\\+Redesign|Lifestyle|Nest|New\\+2015\\+Logo|Notebooks\\+Journals|Office|Shop\\+by\\+Brand|Small\\+Goods|Stationery|Wearables'
                          OR
                          COALESCE(segments[4]::string,'') RLIKE '(?i)Accessories|Apparel|Brands|Campus\\+Collection|Drinkware|Electronics|Google\\+Redesign|Lifestyle|Nest|New\\+2015\\+Logo|Notebooks\\+Journals|Office|Shop\\+by\\+Brand|Small\\+Goods|Stationery|Wearables'
                     )
                THEN 1 ELSE 0
            END
        )                                                           AS pdp_views
    FROM classified
)
SELECT
    ROUND( (pdp_views / total_views)::FLOAT * 100 , 4 )  AS "PDP_PAGE_VIEW_PERCENTAGE"
FROM metrics;