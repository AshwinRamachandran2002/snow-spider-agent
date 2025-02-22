-- Task: Determine the total number of US patents with publication numbers containing 'B2', granted between January 1st, 2008, and December 31st, 2018, that have at least one claim where the claim text does not include the word 'claim'.
WITH patents_sample AS (
  SELECT 
    t1."publication_number" AS publication_number,
    claim.value:"text" AS claims_text
  FROM 
    PATENTS.PATENTS.PUBLICATIONS t1,
    LATERAL FLATTEN(input => t1."claims_localized") AS claim
  WHERE 
    t1."country_code" = 'US'
    AND t1."grant_date" BETWEEN 20080101 AND 20181231
    AND t1."grant_date" != 0
    AND t1."publication_number" LIKE '%B2%'
),
Publication_data AS (
  SELECT
    publication_number,
    COUNT_IF(claims_text NOT LIKE '%claim%') AS nb_indep_claims
  FROM
    patents_sample
  GROUP BY
    publication_number
)
    
SELECT COUNT(nb_indep_claims)
FROM Publication_data
WHERE nb_indep_claims != 0