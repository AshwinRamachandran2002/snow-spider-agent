WITH "cohort" AS (
  SELECT "id_bioguide", DATE("term_start") AS "start_date"
  FROM "legislators_terms"
  WHERE "state" = 'CO'
    AND "term_number" = 1
    AND "term_start" >= '1917-01-01'
    AND "term_start" <= '1999-12-31'
    AND "term_start" IS NOT NULL
),
"numbers"(n) AS (
  SELECT 0
  UNION ALL
  SELECT n + 1 FROM "numbers" WHERE n < 19
),
"cohort_years" AS (
  SELECT c."id_bioguide", c."start_date", n.n AS "year_offset",
         DATE(c."start_date", '+' || n.n || ' years') AS "year_date"
  FROM "cohort" c
  CROSS JOIN "numbers" n
),
"terms" AS (
  SELECT "id_bioguide", DATE("term_start") AS "term_start", DATE("term_end") AS "term_end"
  FROM "legislators_terms"
  WHERE "term_start" IS NOT NULL AND "term_end" IS NOT NULL
),
"service" AS (
  SELECT cy."id_bioguide", cy."year_offset", cy."year_date",
         CASE WHEN EXISTS (
           SELECT 1 FROM "terms" t
           WHERE t."id_bioguide" = cy."id_bioguide"
             AND t."term_start" <= cy."year_date"
             AND t."term_end" >= cy."year_date"
         ) THEN 1 ELSE 0 END AS "in_office"
  FROM "cohort_years" cy
)
SELECT "year_offset" + 1 AS "Year",
       ROUND(100.0 * SUM("in_office") / COUNT(*), 4) AS "Retention_Rate"
FROM "service"
GROUP BY "Year"
ORDER BY "Year";