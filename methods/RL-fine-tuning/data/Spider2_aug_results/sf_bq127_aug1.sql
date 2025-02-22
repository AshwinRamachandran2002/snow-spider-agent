-- Task: For each publication family whose earliest publication date is in January 2015, provide the earliest publication date, the publication numbers, and country codes as comma-separated values sorted alphabetically. Limit the results to 100 records.
SELECT
  "family_id",
  MIN("publication_date") AS "publication_date",
  LISTAGG("publication_number", ',') WITHIN GROUP (ORDER BY "publication_number") AS "publication_number",
  LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY "country_code") AS "country_code"
FROM
  "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" AS p
GROUP BY
  "family_id"
HAVING
  MIN("publication_date") BETWEEN 20150101 AND 20150131
LIMIT 100;