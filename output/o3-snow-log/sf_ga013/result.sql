/*  Pages viewed by user 1402138.5184246691 on 2-Jan-2021
    with PDP / PLP labelling according to the refined rules  */

SELECT DISTINCT
       ttl.value:"value":"string_value"::STRING                                   AS "page_name",
       CASE
            /* PDP: URL contains a “+” in the last segment                                */
            WHEN loc.value:"value":"string_value"::STRING ILIKE '%+%'                     THEN 'PDP'

            /* PLP: URL matches any recognised category path (no “+” sign)               */
            WHEN loc.value:"value":"string_value"::STRING ILIKE ANY
                 ( '%/Accessories/%','%/Apparel/%','%/Brands/%','%/Campus%Collection/%',
                   '%/Drinkware/%','%/Electronics/%','%/Google%Redesign/%','%/Lifestyle/%',
                   '%/Nest/%','%/New%2015%20Logo/%','%/Notebooks%Journals/%','%/Office/%',
                   '%/Shop%by%Brand/%','%/Small%Goods/%','%/Stationery/%','%/Wearables/%')
                                                                                          THEN 'PLP'
            ELSE 'OTHER'
       END                                                                                AS "page_type"
FROM   "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102"  AS t
       ,LATERAL FLATTEN(input => t."EVENT_PARAMS")                 AS loc   -- page_location
       ,LATERAL FLATTEN(input => t."EVENT_PARAMS")                 AS ttl   -- page_title
WHERE  t."EVENT_DATE"   = '20210102'
  AND  t."USER_PSEUDO_ID" = '1402138.5184246691'
  AND  loc.value:"key"::STRING = 'page_location'
  AND  ttl.value:"key"::STRING = 'page_title'
ORDER BY "page_name";