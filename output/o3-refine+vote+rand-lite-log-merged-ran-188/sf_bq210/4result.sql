SELECT COUNT(*) AS "us_b2_patents_without_word_claim"
FROM PATENTS.PATENTS.PUBLICATIONS
WHERE "country_code" = 'US'
  AND "kind_code" = 'B2'
  AND "grant_date" BETWEEN 20080101 AND 20181231
  AND "claims_localized" IS NOT NULL
  AND LOWER("claims_localized"::STRING) NOT LIKE '%claim%';