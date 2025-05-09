/*  Pages visited by user 1402138.5184246691 on 02-Jan-2021
    – “PAGE_LOCATION” shows the URL
    – “PAGE_TYPE” classifies each URL as PDP or PLP                    */

SELECT DISTINCT
       pl.value:"value":"string_value"::STRING                         AS "PAGE_LOCATION",
       CASE 
            WHEN POSITION('+' IN pl.value:"value":"string_value"::STRING) > 0 
                 THEN 'PDP'
            ELSE 'PLP'
       END                                                             AS "PAGE_TYPE"
FROM   GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"   t,
       LATERAL FLATTEN( INPUT => t."EVENT_PARAMS")              pl
WHERE  t."EVENT_DATE"      = '20210102'
  AND  t."USER_PSEUDO_ID"  = '1402138.5184246691'
  AND  pl.value:"key"::STRING = 'page_location'
ORDER BY "PAGE_LOCATION";