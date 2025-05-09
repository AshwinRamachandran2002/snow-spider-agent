WITH numbers AS (
    SELECT column1 AS "Year" 
    FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
                 (11),(12),(13),(14),(15),(16),(17),(18),(19),(20))
),
cohort AS (
    SELECT DISTINCT "id_bioguide", TO_DATE("term_start", 'YYYY-MM-DD') AS "first_term_start"
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS"
    WHERE "state" = 'CO' 
      AND "term_number" = 1 
      AND TO_DATE("term_start", 'YYYY-MM-DD') BETWEEN '1917-01-01' AND '1999-12-31'
),
legislator_service AS (
    SELECT c."id_bioguide", c."first_term_start", MAX(TO_DATE(t."term_end", 'YYYY-MM-DD')) AS "last_term_end"
    FROM cohort c
    JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t
        ON c."id_bioguide" = t."id_bioguide"
    GROUP BY c."id_bioguide", c."first_term_start"
),
retention AS (
    SELECT n."Year", COUNT(*) AS "remaining"
    FROM numbers n
    JOIN legislator_service ls
        ON DATEDIFF('year', ls."first_term_start", ls."last_term_end") >= n."Year"
    GROUP BY n."Year"
),
total_cohort AS (
    SELECT COUNT(DISTINCT "id_bioguide") AS "total"
    FROM cohort
)
SELECT n."Year",
       ROUND(COALESCE(r."remaining", 0) * 100.0 / tc."total", 4) AS "Retention_Rate"
FROM numbers n
LEFT JOIN retention r ON n."Year" = r."Year"
CROSS JOIN total_cohort tc
ORDER BY n."Year";