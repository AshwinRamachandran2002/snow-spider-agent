WITH RECURSIVE
  years AS (
    SELECT 1800 AS y
    UNION ALL
    SELECT y + 1 FROM years WHERE y + 1 <= 2023
  ),
  male_la_legislators AS (
    SELECT l."id_bioguide", MIN(DATE(lt."term_start")) AS "first_term_start"
    FROM "legislators_terms" AS lt
    JOIN "legislators" AS l ON l."id_bioguide" = lt."id_bioguide"
    WHERE l."gender" = 'M' AND lt."state" = 'LA'
    GROUP BY l."id_bioguide"
  ),
  active_service AS (
    SELECT
      ft."id_bioguide",
      years.y AS "year",
      ft."first_term_start",
      (julianday(DATE(years.y || '-12-31')) - julianday(ft."first_term_start")) / 365.25 AS "Years_Since_First_Term"
    FROM male_la_legislators AS ft
    CROSS JOIN years
    JOIN "legislators_terms" AS lt ON lt."id_bioguide" = ft."id_bioguide"
      AND DATE(lt."term_start") <= DATE(years.y || '-12-31') AND DATE(lt."term_end") >= DATE(years.y || '-12-31')
  )
SELECT
  CAST("Years_Since_First_Term" AS INTEGER) AS "Years_Since_First_Term",
  COUNT(DISTINCT "id_bioguide") AS "Number_of_Distinct_Legislators"
FROM active_service
WHERE "Years_Since_First_Term" > 30 AND "Years_Since_First_Term" < 50
GROUP BY "Years_Since_First_Term"
ORDER BY "Years_Since_First_Term";