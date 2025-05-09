WITH
numbers AS (
    SELECT 0 as n UNION ALL
    SELECT 1 UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4 UNION ALL
    SELECT 5 UNION ALL
    SELECT 6 UNION ALL
    SELECT 7 UNION ALL
    SELECT 8 UNION ALL
    SELECT 9 UNION ALL
    SELECT 10 UNION ALL
    SELECT 11 UNION ALL
    SELECT 12 UNION ALL
    SELECT 13 UNION ALL
    SELECT 14 UNION ALL
    SELECT 15 UNION ALL
    SELECT 16 UNION ALL
    SELECT 17 UNION ALL
    SELECT 18 UNION ALL
    SELECT 19
),
initial_cohort AS (
    SELECT DISTINCT "id_bioguide", DATE("term_start") AS "term_start"
    FROM "legislators_terms"
    WHERE "state" = 'CO' AND "term_number" = 1 AND
          "term_start" >= '1917-01-01' AND "term_start" <= '1999-12-31'
),
cohort_size AS (
    SELECT COUNT(*) AS "initial_cohort_size" FROM initial_cohort
),
cohort_years AS (
    SELECT ic."id_bioguide", ic."term_start", n.n AS "year_elapsed",
           DATE(ic."term_start", '+' || n.n || ' years') AS "date_in_n_years"
    FROM initial_cohort ic CROSS JOIN numbers n
),
serving_status AS (
    SELECT cy."year_elapsed", cy."id_bioguide"
    FROM cohort_years cy
    INNER JOIN "legislators_terms" lt ON lt."id_bioguide" = cy."id_bioguide" AND lt."state" = 'CO'
    WHERE DATE(cy."date_in_n_years") BETWEEN DATE(lt."term_start") AND DATE(lt."term_end")
),
yearly_retention AS (
    SELECT ss."year_elapsed", COUNT(DISTINCT ss."id_bioguide") AS "num_serving"
    FROM serving_status ss
    GROUP BY ss."year_elapsed"
),
total_cohort AS (
    SELECT "initial_cohort_size" FROM cohort_size
)
SELECT yr."year_elapsed" + 1 AS "Year",
       ROUND((CAST(yr."num_serving" AS REAL) / tc."initial_cohort_size") * 100.0, 4) AS "Retention_Rate"
FROM yearly_retention yr, total_cohort tc
ORDER BY "Year";