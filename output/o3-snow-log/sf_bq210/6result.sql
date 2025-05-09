WITH patents_without_word_claim AS (
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."claims_localized") AS f
    WHERE p."country_code" = 'US'
      AND p."kind_code"   = 'B2'
      AND p."grant_date" BETWEEN 20080101 AND 20181231
      AND LOWER(f.value:"text"::STRING) NOT ILIKE '%claim%'
)
SELECT COUNT(*) AS "num_us_b2_patents_2008_2018_without_word_claim"
FROM patents_without_word_claim;