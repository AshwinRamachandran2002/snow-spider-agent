WITH movies_with_year AS (
    SELECT mo."MID", REGEXP_SUBSTR(mo."year", '\\d{4}') AS "Year"
    FROM DB_IMDB.DB_IMDB.MOVIE mo
),
cast_counts AS (
    SELECT m."MID",
           SUM(CASE WHEN TRIM(p."Gender") = 'Male' THEN 1 ELSE 0 END) AS "Male_Cast_Count",
           SUM(CASE WHEN TRIM(p."Gender") = 'Female' THEN 1 ELSE 0 END) AS "Female_Cast_Count",
           SUM(CASE WHEN TRIM(p."Gender") IS NULL OR TRIM(p."Gender") = '' THEN 1 ELSE 0 END) AS "Unknown_Gender_Count"
    FROM DB_IMDB.DB_IMDB.M_CAST m
    LEFT JOIN DB_IMDB.DB_IMDB.PERSON p ON TRIM(m."PID") = TRIM(p."PID")
    GROUP BY m."MID"
),
movies_all_female AS (
    SELECT
        movies_with_year."Year",
        CASE WHEN cast_counts."Male_Cast_Count" = 0 
                  AND cast_counts."Unknown_Gender_Count" = 0 
                  AND cast_counts."Female_Cast_Count" > 0 THEN 1 ELSE 0 END AS "Is_All_Female"
    FROM movies_with_year
    LEFT JOIN cast_counts ON movies_with_year."MID" = cast_counts."MID"
)
SELECT
    "Year",
    ROUND(SUM("Is_All_Female") * 1.0 / COUNT(*), 4) AS "Proportion of Female-Actor-Only Films",
    COUNT(*) AS "Total Number of All Films"
FROM movies_all_female
WHERE "Year" IS NOT NULL
GROUP BY "Year"
ORDER BY "Year";