SELECT COUNT(DISTINCT "publication_number") AS "num_patents_without_word_claim"
FROM PATENTS.PATENTS.PUBLICATIONS
WHERE "country_code" = 'US'
  AND "kind_code" = 'B2'
  AND "grant_date" BETWEEN 20080101 AND 20181231
  AND "claims_localized" IS NOT NULL
  AND LOWER(TO_VARCHAR("claims_localized")) NOT LIKE '%claim%';