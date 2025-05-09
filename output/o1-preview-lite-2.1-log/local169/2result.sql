WITH
numbers(n) AS (
    SELECT 0
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 20
),
cohort AS (
    SELECT DISTINCT "id_bioguide", date("term_start") AS "start_date"
    FROM "legislators_terms"
    WHERE "state" = 'CO'
      AND "term_number" = 1
      AND date("term_start") >= '1917-01-01'
      AND date("term_start") <= '1999-12-31'
),
dates AS (
    SELECT c."id_bioguide", c."start_date", n.n AS "Year",
           date(c."start_date", '+' || n.n || ' years') AS "date_n"
    FROM cohort c
    CROSS JOIN numbers n
),
in_office AS (
    SELECT d."Year", d."id_bioguide",
           CASE WHEN EXISTS (
               SELECT 1 FROM "legislators_terms" t
               WHERE t."id_bioguide" = d."id_bioguide"
                 AND date(t."term_start") <= d."date_n"
                 AND date(t."term_end") >= d."date_n"
           ) THEN 1 ELSE 0 END AS "in_office"
    FROM dates d
),
retention AS (
    SELECT "Year", 100.0 * SUM("in_office") / (SELECT COUNT(*) FROM cohort) AS "Retention_Rate"
    FROM in_office
    GROUP BY "Year"
)
SELECT "Year", ROUND("Retention_Rate", 4) AS "Retention_Rate"
FROM retention
ORDER BY "Year";