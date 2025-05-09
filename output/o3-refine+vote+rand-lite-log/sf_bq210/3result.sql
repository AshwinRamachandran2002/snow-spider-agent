SELECT 
    COUNT(DISTINCT "publication_number") AS "num_us_b2_patents_without_word_claim_in_claims"
FROM PATENTS.PATENTS.PUBLICATIONS
WHERE "country_code" = 'US'
  AND "kind_code" = 'B2'
  AND "grant_date" BETWEEN 20080101 AND 20181231
  AND "claims_localized" IS NOT NULL
  AND UPPER(TO_VARCHAR("claims_localized")) NOT LIKE '%CLAIM%';