WITH us_b2_2008_2018 AS (
    SELECT 
        p."publication_number" AS publication_number,          -- alias without quotes for later use
        cl.value:"text"::string  AS claim_text
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."claims_localized") cl
    WHERE p."country_code" = 'US'
      AND p."kind_code"    = 'B2'
      AND p."grant_date" BETWEEN 20080101 AND 20181231
      AND cl.value:"text" IS NOT NULL
)
SELECT COUNT(*) AS "US_B2_patents_without_word_claim"
FROM (
    SELECT 
        publication_number
    FROM us_b2_2008_2018
    GROUP BY publication_number
    HAVING SUM(
               CASE
                   WHEN REGEXP_LIKE(LOWER(claim_text), '\\bclaim\\b')
                   THEN 1 ELSE 0
               END
             ) = 0      -- no claims contain the exact word 'claim'
) AS q;