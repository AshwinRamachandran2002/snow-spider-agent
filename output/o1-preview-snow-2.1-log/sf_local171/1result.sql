WITH legislator_service AS (
  SELECT
    l."id_bioguide",
    DATEDIFF(
      'day',
      MIN(TRY_TO_DATE(t."term_start", 'YYYY-MM-DD')),
      MAX(TRY_TO_DATE(t."term_end", 'YYYY-MM-DD'))
    ) / 365.25 AS years_of_service
  FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS" l
  JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t
    ON l."id_bioguide" = t."id_bioguide"
  WHERE l."gender" = 'M' AND t."state" = 'LA'
    AND TRY_TO_DATE(t."term_start", 'YYYY-MM-DD') IS NOT NULL
    AND TRY_TO_DATE(t."term_end", 'YYYY-MM-DD') IS NOT NULL
  GROUP BY l."id_bioguide"
)
SELECT
  ROUND(years_of_service, 4) AS "Years_of_Service",
  COUNT(*) AS "Number_of_Legislators"
FROM legislator_service
WHERE years_of_service > 30 AND years_of_service < 50
GROUP BY ROUND(years_of_service, 4)
ORDER BY "Years_of_Service";