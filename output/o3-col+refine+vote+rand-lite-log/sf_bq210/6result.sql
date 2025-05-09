SELECT
  COUNT(*) AS "us_b2_grants_2008_2018_with_at_least_one_claim_without_word_claim"
FROM (
  SELECT
    p."publication_number"
  FROM PATENTS.PATENTS.PUBLICATIONS AS p,
       LATERAL FLATTEN(input => p."claims_localized") AS f
  WHERE p."country_code" = 'US'
    AND p."kind_code"    = 'B2'
    AND p."grant_date"  BETWEEN 20080101 AND 20181231
    AND f.value:"text"::STRING NOT ILIKE '%claim%'
  GROUP BY p."publication_number"
) AS sub;