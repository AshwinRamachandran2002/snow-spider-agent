SELECT COUNT(DISTINCT t."publication_number") AS "num_us_b2_without_word_claim"
FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
     LATERAL FLATTEN (INPUT => t."claims_localized") f
WHERE t."country_code" = 'US'
  AND t."kind_code"    = 'B2'
  AND t."grant_date" BETWEEN 20080101 AND 20181231
  AND f.value:"language"::STRING = 'en'
  AND f.value:"text"::STRING NOT ILIKE '%claim%';