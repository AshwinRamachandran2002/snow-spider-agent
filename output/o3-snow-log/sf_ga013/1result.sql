/*  Pages visited by user 1402138.5184246691 on 2021-01-02
    – page names normalised so that product detail pages show “PDP”
      and product listing pages show “PLP”.
*/
WITH base AS (
    /* Pull, per-event, the URL (page_location) and page_title */
    SELECT
           t."EVENT_TIMESTAMP",
           MAX(CASE WHEN f.value:"key"::STRING = 'page_location'
                    THEN f.value:"string_value"::STRING END) AS "PAGE_LOCATION",
           MAX(CASE WHEN f.value:"key"::STRING = 'page_title'
                    THEN f.value:"string_value"::STRING END) AS "PAGE_TITLE"
    FROM  GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  t,
          LATERAL FLATTEN(INPUT => t."EVENT_PARAMS")            f
    WHERE t."EVENT_DATE"     = '20210102'
      AND t."USER_PSEUDO_ID" = '1402138.5184246691'
    GROUP BY t."EVENT_TIMESTAMP"
)
SELECT DISTINCT
       CASE
            /* PDP : last URL segment contains “+” (e.g. product-name) */
            WHEN SPLIT_PART("PAGE_LOCATION", '/', -1) ILIKE '%+%'            THEN 'PDP'
            /* PLP : at least five URL segments and no “+” in last segment */
            WHEN ARRAY_SIZE(SPLIT("PAGE_LOCATION", '/')) >= 5                THEN 'PLP'
            /* Otherwise : show the original page title (or the raw URL if no title) */
            ELSE COALESCE(NULLIF("PAGE_TITLE", ''), "PAGE_LOCATION")
       END                                                        AS "PAGE_NAME"
FROM   base
ORDER  BY "PAGE_NAME";