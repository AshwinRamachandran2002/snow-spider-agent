SELECT COUNT(*) AS "num_patents_without_word_claim"
FROM PATENTS.PATENTS.PUBLICATIONS
WHERE "country_code" = 'US'
  AND "kind_code" = 'B2'
  AND "grant_date" BETWEEN 20080101 AND 20181231
  AND LOWER(COALESCE("claims_localized"::STRING,
                     "claims_localized_html"::STRING)) NOT LIKE '%claim%';