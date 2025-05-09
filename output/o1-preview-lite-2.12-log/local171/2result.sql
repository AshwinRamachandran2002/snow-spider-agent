WITH RECURSIVE
numbers(n) AS (
    SELECT 31
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n + 1 < 50
),
terms AS (
    SELECT
        lt.*,
        CASE WHEN lt."term_end" IS NULL OR lt."term_end" = 'Present' THEN '9999-12-31' ELSE lt."term_end" END AS "term_end_fixed"
        FROM "legislators_terms" lt
    ),
first_terms AS (
    SELECT l."id_bioguide", MIN(lt."term_start") AS "first_term_start"
    FROM "legislators" l
    JOIN terms lt ON l."id_bioguide" = lt."id_bioguide"
    WHERE l."gender" = 'M' AND lt."state" = 'LA' AND lt."term_start" IS NOT NULL
    GROUP BY l."id_bioguide"
),
dates AS (
    SELECT
        ft."id_bioguide",
        numbers.n AS "Years_Since_First_Term",
        DATE(STRFTIME('%Y', ft."first_term_start", '+' || numbers.n || ' years') || '-12-31') AS "Date_N"
    FROM first_terms ft
    CROSS JOIN numbers
),
active_service AS (
    SELECT
        dates."Years_Since_First_Term",
        dates."id_bioguide"
    FROM dates
    JOIN terms lt ON dates."id_bioguide" = lt."id_bioguide"
    WHERE
        lt."term_start" <= dates."Date_N"
        AND lt."term_end_fixed" >= dates."Date_N"
    GROUP BY dates."id_bioguide", dates."Years_Since_First_Term"
)
SELECT
    "Years_Since_First_Term",
    COUNT(DISTINCT "id_bioguide") AS "Number_of_Distinct_Legislators"
FROM active_service
GROUP BY "Years_Since_First_Term"
ORDER BY "Years_Since_First_Term";