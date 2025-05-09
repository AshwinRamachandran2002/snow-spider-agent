WITH cohort AS (
    SELECT "id_bioguide",
           MIN(TO_DATE("term_start", 'YYYY-MM-DD')) AS "first_term_start_date",
           MAX(TO_DATE("term_end", 'YYYY-MM-DD')) AS "last_term_end_date"
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS"
    WHERE "state" = 'CO' AND "term_number" = 1
      AND TO_DATE("term_start", 'YYYY-MM-DD') BETWEEN DATE '1917-01-01' AND DATE '1999-12-31'
    GROUP BY "id_bioguide"
),
years AS (
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) AS "Year"
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),
retention AS (
    SELECT y."Year",
           COUNT(*) AS "Total_Legislators",
           SUM(CASE WHEN c."last_term_end_date" >= DATEADD('YEAR', y."Year", c."first_term_start_date") THEN 1 ELSE 0 END) AS "Legislators_Remaining"
    FROM cohort c CROSS JOIN years y
    GROUP BY y."Year"
)
SELECT "Year",
       ROUND("Legislators_Remaining" * 100.0 / (SELECT COUNT(*) FROM cohort), 4) AS "Retention_Rate"
FROM retention
ORDER BY "Year";