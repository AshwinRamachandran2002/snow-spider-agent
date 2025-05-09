/*  Pages (URL or Title) visited by user 1402138.5184246691 on 02-Jan-2021
    together with their refined PDP / PLP / OTHER classification          */
WITH user_events AS (   --  pull one row per GA4 event with its location & title
    SELECT
           t."EVENT_TIMESTAMP",
           MAX(CASE WHEN f.value:"key"::STRING = 'page_location'
                    THEN f.value:"value":"string_value"::STRING END) AS "page_location",
           MAX(CASE WHEN f.value:"key"::STRING = 'page_title'
                    THEN f.value:"value":"string_value"::STRING END) AS "page_title"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  AS t
         ,LATERAL FLATTEN (INPUT => t."EVENT_PARAMS")            AS f
    WHERE t."USER_PSEUDO_ID" = '1402138.5184246691'
      AND t."EVENT_DATE"      = '20210102'
    GROUP BY t."EVENT_TIMESTAMP"
)
SELECT DISTINCT
       COALESCE("page_title", "page_location")                                   AS "page_name",
       CASE
           /* ---------- PDP (Product-Detail Page) ---------- */
           WHEN "page_location" IS NOT NULL
                /* “+” in final path segment … */
                AND REGEXP_LIKE(LOWER("page_location"), '/[^/]*\\+[^/]*$')
                /* … and a recognised category in 4th or 5th segment              */
                AND (
                     REGEXP_LIKE(LOWER(SPLIT_PART("page_location", '/', 4)),
                                 '(accessories|apparel|brands|campus\\s*collection|drinkware|electronics|google\\s*redesign|lifestyle|nest|new\\s*2015\\s*logo|notebooks\\s*journals|office|shop\\s*by\\s*brand|small\\s*goods|stationery|wearables)')
                     OR
                     REGEXP_LIKE(LOWER(SPLIT_PART("page_location", '/', 5)),
                                 '(accessories|apparel|brands|campus\\s*collection|drinkware|electronics|google\\s*redesign|lifestyle|nest|new\\s*2015\\s*logo|notebooks\\s*journals|office|shop\\s*by\\s*brand|small\\s*goods|stationery|wearables)')
                )
                THEN 'PDP'

           /* ---------- PLP (Product-Listing Page) ---------- */
           WHEN "page_location" IS NOT NULL
                /* no “+” in 4th / 5th segment … */
                AND POSITION('+' IN SPLIT_PART("page_location", '/', 4)) = 0
                AND POSITION('+' IN SPLIT_PART("page_location", '/', 5)) = 0
                /* … but a recognised category present                                  */
                AND (
                     REGEXP_LIKE(LOWER(SPLIT_PART("page_location", '/', 4)),
                                 '(accessories|apparel|brands|campus\\s*collection|drinkware|electronics|google\\s*redesign|lifestyle|nest|new\\s*2015\\s*logo|notebooks\\s*journals|office|shop\\s*by\\s*brand|small\\s*goods|stationery|wearables)')
                     OR
                     REGEXP_LIKE(LOWER(SPLIT_PART("page_location", '/', 5)),
                                 '(accessories|apparel|brands|campus\\s*collection|drinkware|electronics|google\\s*redesign|lifestyle|nest|new\\s*2015\\s*logo|notebooks\\s*journals|office|shop\\s*by\\s*brand|small\\s*goods|stationery|wearables)')
                )
                THEN 'PLP'

           /* ---------- anything else ---------- */
           ELSE 'OTHER'
       END                                                                       AS "page_type"
FROM user_events
WHERE "page_location" IS NOT NULL
ORDER BY "page_name" ASC NULLS LAST;