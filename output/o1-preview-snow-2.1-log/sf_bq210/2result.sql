WITH patents_with_claim_term AS (
  SELECT DISTINCT p."publication_number"
  FROM PATENTS.PATENTS.PUBLICATIONS p,
       LATERAL FLATTEN(input => p."claims_localized") f
  WHERE p."country_code" = 'US'
    AND p."kind_code" = 'B2'
    AND p."grant_date" BETWEEN 20080101 AND 20181231
    AND f.value::STRING ILIKE '%claim%'
)
SELECT COUNT(DISTINCT p."publication_number") AS num
FROM PATENTS.PATENTS.PUBLICATIONS p
WHERE p."country_code" = 'US'
  AND p."kind_code" = 'B2'
  AND p."grant_date" BETWEEN 20080101 AND 20181231
  AND p."publication_number" NOT IN (SELECT "publication_number" FROM patents_with_claim_term);