SELECT COUNT(DISTINCT t."publication_number") AS "number_of_patents"
FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
     LATERAL FLATTEN(input => t."claims_localized") f
WHERE t."country_code" = 'US'
  AND t."kind_code" = 'B2'
  AND TRY_TO_DATE(t."grant_date"::VARCHAR, 'YYYYMMDD') BETWEEN '2008-01-01' AND '2018-12-31'
  AND f.value:"language"::STRING = 'en'
  AND f.value:"text"::STRING IS NOT NULL
  AND f.value:"text"::STRING NOT ILIKE '%claim%';