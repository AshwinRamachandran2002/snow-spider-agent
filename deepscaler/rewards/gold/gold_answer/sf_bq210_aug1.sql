-- Task: Retrieve up to 100 publication numbers and claims texts of US B2 patents granted between 2008 and 2018.
SELECT 
  t1."publication_number" AS "publication_number",
  claim.value:"text" AS "claims_text"
FROM 
  PATENTS.PATENTS.PUBLICATIONS t1,
  LATERAL FLATTEN(input => t1."claims_localized") AS claim
WHERE 
  t1."country_code" = 'US'
  AND t1."grant_date" BETWEEN 20080101 AND 20181231
  AND t1."grant_date" != 0
  AND t1."publication_number" LIKE '%B2%'
LIMIT 100