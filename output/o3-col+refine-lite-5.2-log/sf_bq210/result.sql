WITH flat AS (
    SELECT  
        p."publication_number",
        MAX(
            CASE 
                WHEN f.value:"text"::STRING ILIKE '%claim%' THEN 1 
                ELSE 0 
            END
        ) AS "has_claim_word"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."claims_localized") f
    WHERE p."country_code" = 'US'
      AND p."kind_code"    = 'B2'
      AND p."grant_date"  BETWEEN 20080101 AND 20181231
    GROUP BY p."publication_number"
)
SELECT COUNT(*) AS "num_us_b2_patents_without_word_claim"
FROM   flat
WHERE  "has_claim_word" = 0;