/*  Pages visited by user 1402138.5184246691 on 2-Jan-2021
    – A “page” is taken from page_title when available, otherwise the raw
      page_location URL is used.
    – Pages whose URL contains a “+” in the last segment are tagged PDP,
      all others are tagged PLP.                                           */
WITH user_sessions AS (
    SELECT
        loc.value:"value":"string_value"::STRING  AS PAGE_LOCATION_URL ,
        ttl.value:"value":"string_value"::STRING  AS PAGE_TITLE
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  e
         ,LATERAL FLATTEN ( INPUT => e."EVENT_PARAMS")  loc
         ,LATERAL FLATTEN ( INPUT => e."EVENT_PARAMS")  ttl
    WHERE e."USER_PSEUDO_ID" = '1402138.5184246691'
      AND e."EVENT_DATE"     = '20210102'
      AND loc.value:"key"::STRING = 'page_location'
      AND ttl.value:"key"::STRING = 'page_title'
)
SELECT DISTINCT
       COALESCE(PAGE_TITLE , PAGE_LOCATION_URL)               AS PAGE_NAME ,
       CASE 
            /* “+” in URL’s last segment → PDP, otherwise PLP */
            WHEN SPLIT_PART(PAGE_LOCATION_URL,'/',-1) ILIKE '%+%' THEN 'PDP'
            ELSE 'PLP'
       END                                                   AS PAGE_TYPE
FROM user_sessions
ORDER BY PAGE_NAME;