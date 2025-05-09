SELECT
    COUNT(DISTINCT t."publication_number") AS "patent_count"
FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
     LATERAL FLATTEN(input => t."claims_localized") f
WHERE t."country_code"  = 'US'
  AND t."kind_code"     = 'B2'
  AND t."grant_date" BETWEEN 20080101 AND 20181231
  AND f.value:"text"::STRING NOT ILIKE '%claim%';