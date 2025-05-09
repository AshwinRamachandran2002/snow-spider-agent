SELECT
  COUNT(DISTINCT p."publication_number") AS "us_b2_patents_no_claim_word"
FROM PATENTS.PATENTS.PUBLICATIONS AS p,
     LATERAL FLATTEN(input => p."claims_localized") AS cl
WHERE p."country_code" = 'US'
  AND p."kind_code" ILIKE '%B2'
  AND p."grant_date" BETWEEN 20080101 AND 20181231
  AND cl.value:"language"::STRING = 'en'
  AND LOWER(cl.value:"text"::STRING) NOT ILIKE '%claim%';