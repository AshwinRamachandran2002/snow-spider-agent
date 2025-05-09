WITH first_terms AS (
    SELECT l."id_bioguide", MIN(lt."term_start") AS "first_term_start"
    FROM "legislators" l
    JOIN "legislators_terms" lt ON l."id_bioguide" = lt."id_bioguide"
    WHERE l."gender" = 'M' AND lt."state" = 'LA' AND lt."term_start" IS NOT NULL
    GROUP BY l."id_bioguide"
),
years_since_first_term(n) AS (
    SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
    UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40
    UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45
    UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49
),
dates AS (
    SELECT ft."id_bioguide", ft."first_term_start", y.n AS "years_since_first_term",
           date((CAST(strftime('%Y', ft."first_term_start") AS INTEGER) + y.n) || '-12-31') AS "date_checked"
    FROM first_terms ft
    CROSS JOIN years_since_first_term y
),
valid_dates AS (
    SELECT DISTINCT d."years_since_first_term", d."id_bioguide"
    FROM dates d
    JOIN "legislators_terms" lt ON d."id_bioguide" = lt."id_bioguide"
    WHERE lt."term_start" <= d."date_checked" AND lt."term_end" >= d."date_checked"
      AND lt."term_start" IS NOT NULL AND lt."term_end" IS NOT NULL
)
SELECT vd."years_since_first_term" AS "Years_Since_First_Term",
       COUNT(DISTINCT vd."id_bioguide") AS "Number_of_Distinct_Legislators"
FROM valid_dates vd
GROUP BY vd."years_since_first_term"
ORDER BY vd."years_since_first_term";