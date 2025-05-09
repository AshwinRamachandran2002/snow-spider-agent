WITH numbers AS (
  SELECT 1 AS "year_n"
  UNION ALL
  SELECT "year_n" + 1 FROM numbers WHERE "year_n" < 20
),
first_terms AS
(
 SELECT "id_bioguide",
        MIN(TO_DATE("term_start")) AS "first_term_start"
 FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
 WHERE "state" = 'CO' AND "term_start" IS NOT NULL
 GROUP BY "id_bioguide"
 HAVING MIN(TO_DATE("term_start")) BETWEEN '1917-01-01' AND '1999-12-31'
),
terms AS
(
 SELECT "id_bioguide",
        TO_DATE("term_start") AS "term_start_date",
        TO_DATE("term_end") AS "term_end_date"
 FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
 WHERE "term_start" IS NOT NULL AND "term_end" IS NOT NULL AND "state" = 'CO'
),
per_legislator_year AS
(
  SELECT
    F."id_bioguide",
    N."year_n",
    DATEADD(year, N."year_n" - 1, F."first_term_start") AS "current_date"
  FROM
    first_terms F
  CROSS JOIN
    numbers N
),
in_office AS
(
 SELECT
   PLY."year_n",
   PLY."id_bioguide",
   CASE WHEN EXISTS (
     SELECT 1 FROM terms T 
     WHERE T."id_bioguide" = PLY."id_bioguide"
       AND PLY."current_date" BETWEEN T."term_start_date" AND T."term_end_date")
   THEN 1 ELSE 0 END AS "in_office"
 FROM per_legislator_year PLY
)
SELECT
  I."year_n" AS "Year",
  ROUND((SUM(I."in_office") * 100.0)/ total."total_legislators", 4) AS "Retention_Rate"
FROM
  in_office I
CROSS JOIN
  (SELECT COUNT(*) AS "total_legislators" FROM first_terms) AS total
GROUP BY
  I."year_n", total."total_legislators"
ORDER BY
  I."year_n";