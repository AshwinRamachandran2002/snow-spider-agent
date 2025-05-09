/*  Pages visited by user 1402138.5184246691 on 2021-01-02
    – when the URL meets PDP / PLP criteria the page name
      is replaced by ‘PDP’ or ‘PLP’; otherwise the original
      page_title is kept.                                              */
WITH page_hits AS (    -- isolate one row per page_view hit
    SELECT
        t."EVENT_TIMESTAMP",
        MAX( CASE WHEN ep.value:"key"::STRING = 'page_title'
                  THEN ep.value:"value":"string_value"::STRING END ) AS page_title,
        MAX( CASE WHEN ep.value:"key"::STRING = 'page_location'
                  THEN ep.value:"value":"string_value"::STRING END ) AS page_location
    FROM  GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  t,
          LATERAL FLATTEN ( INPUT => t."EVENT_PARAMS" )            ep
    WHERE t."USER_PSEUDO_ID" = '1402138.5184246691'
      AND t."EVENT_NAME"     = 'page_view'
    GROUP BY t."EVENT_TIMESTAMP"
),
classified AS (        -- classify each hit as PDP / PLP / OTHER
    SELECT DISTINCT
           page_title,
           page_location,
           CASE
               /* PDP : last URL segment contains '+'
                         AND 4th or 5th segment is a known category  */
               WHEN POSITION('+' IN SPLIT_PART(page_location,'/',-1)) > 0
                    AND (
                         REGEXP_LIKE( SPLIT_PART(page_location,'/',4),
                                      '(Accessories|Apparel|Brands|Campus\\s*Collection|Drinkware|Electronics|Google\\s*Redesign|Lifestyle|Nest|New\\s*2015\\s*Logo|Notebooks\\s*Journals|Office|Shop\\s*by\\s*Brand|Small\\s*Goods|Stationery|Wearables)',
                                      'i')
                      OR REGEXP_LIKE( SPLIT_PART(page_location,'/',5),
                                      '(Accessories|Apparel|Brands|Campus\\s*Collection|Drinkware|Electronics|Google\\s*Redesign|Lifestyle|Nest|New\\s*2015\\s*Logo|Notebooks\\s*Journals|Office|Shop\\s*by\\s*Brand|Small\\s*Goods|Stationery|Wearables)',
                                      'i')
                    ) THEN 'PDP'

               /* PLP : NO '+' in 4th / 5th segment, category present */
               WHEN POSITION('+' IN SPLIT_PART(page_location,'/',4)) = 0
                    AND POSITION('+' IN SPLIT_PART(page_location,'/',5)) = 0
                    AND (
                         REGEXP_LIKE( SPLIT_PART(page_location,'/',4),
                                      '(Accessories|Apparel|Brands|Campus\\s*Collection|Drinkware|Electronics|Google\\s*Redesign|Lifestyle|Nest|New\\s*2015\\s*Logo|Notebooks\\s*Journals|Office|Shop\\s*by\\s*Brand|Small\\s*Goods|Stationery|Wearables)',
                                      'i')
                      OR REGEXP_LIKE( SPLIT_PART(page_location,'/',5),
                                      '(Accessories|Apparel|Brands|Campus\\s*Collection|Drinkware|Electronics|Google\\s*Redesign|Lifestyle|Nest|New\\s*2015\\s*Logo|Notebooks\\s*Journals|Office|Shop\\s*by\\s*Brand|Small\\s*Goods|Stationery|Wearables)',
                                      'i')
                    ) THEN 'PLP'

               /* otherwise keep the original page title              */
               ELSE page_title
           END AS adjusted_name
    FROM page_hits
)
SELECT DISTINCT
       adjusted_name AS "PAGE_NAME"
FROM   classified
ORDER BY "PAGE_NAME";