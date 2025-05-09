WITH male_legislators_la AS (
    SELECT l."id_bioguide",
           MIN(TO_DATE(t."term_start", 'YYYY-MM-DD')) AS first_term_start
    FROM "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS" l
    INNER JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t
        ON l."id_bioguide" = t."id_bioguide"
    WHERE l."gender" = 'M' AND t."state" = 'LA'
    GROUP BY l."id_bioguide"
),
years AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 30 AS years_elapsed
    FROM TABLE(GENERATOR(ROWCOUNT => 19))
),
all_combinations AS (
    SELECT l."id_bioguide", y.years_elapsed, l.first_term_start,
           DATE_FROM_PARTS(EXTRACT(YEAR FROM DATEADD('year', y.years_elapsed, l.first_term_start)), 12, 31) AS dec31_date
    FROM male_legislators_la l
    CROSS JOIN years y
),
filtered_combos AS (
    SELECT DISTINCT a.years_elapsed, a."id_bioguide"
    FROM all_combinations a
    INNER JOIN "CITY_LEGISLATION"."CITY_LEGISLATION"."LEGISLATORS_TERMS" t2
        ON a."id_bioguide" = t2."id_bioguide"
    WHERE TO_DATE(t2."term_start", 'YYYY-MM-DD') <= a.dec31_date
      AND TO_DATE(t2."term_end", 'YYYY-MM-DD') >= a.dec31_date
)
SELECT years_elapsed, COUNT(DISTINCT "id_bioguide") AS "Number_of_Distinct_Legislators"
FROM filtered_combos
GROUP BY years_elapsed
ORDER BY years_elapsed;