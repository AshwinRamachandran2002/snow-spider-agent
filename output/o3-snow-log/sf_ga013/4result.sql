/*  Pages visited by user 1402138.5184246691 on 02-Jan-2021
    – “page_name” shows the title when available (otherwise the URL)
    – “page_type” classifies the URL as PDP or PLP                      */
WITH per_event AS (   -- one row per event with its page URL & title
    SELECT
        t."EVENT_TIMESTAMP",
        MAX(CASE WHEN f.value:"key"::STRING = 'page_location'
                 THEN f.value:"value":"string_value"::STRING END) AS "page_location",
        MAX(CASE WHEN f.value:"key"::STRING = 'page_title'
                 THEN f.value:"value":"string_value"::STRING END) AS "page_title"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  t,
         LATERAL FLATTEN (INPUT => t."EVENT_PARAMS")            f
    WHERE t."USER_PSEUDO_ID" = '1402138.5184246691'
      AND t."EVENT_DATE"      = '20210102'
    GROUP BY t."EVENT_TIMESTAMP"
),
page_list AS (         -- de-duplicated list of pages with PDP/PLP flag
    SELECT DISTINCT
           COALESCE("page_title", "page_location")                             AS "page_name",
           CASE WHEN REGEXP_LIKE("page_location", '\\+') THEN 'PDP' ELSE 'PLP' END AS "page_type"
    FROM per_event
)
SELECT "page_name",
       "page_type"
FROM   page_list
ORDER BY "page_name";