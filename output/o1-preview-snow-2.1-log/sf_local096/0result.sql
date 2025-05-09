SELECT m."year" AS "Year",
       ROUND(
           COALESCE(
               COUNT(DISTINCT CASE 
                   WHEN per_movie."Male_Actors" = 0 
                        AND per_movie."Female_Actors" > 0 
                        AND per_movie."Unknown_Gender_Actors" = 0 
                   THEN m."MID" END) 
               ::FLOAT / NULLIF(COUNT(DISTINCT m."MID"), 0), 0), 4) AS "Proportion of Female-Actor-Only Films",
       COUNT(DISTINCT m."MID") AS "Total Number of All Films"
FROM DB_IMDB.DB_IMDB."MOVIE" m
JOIN (
    SELECT mc."MID",
           SUM(CASE WHEN LOWER(TRIM(p."Gender")) = 'female' THEN 1 ELSE 0 END) AS "Female_Actors",
           SUM(CASE WHEN LOWER(TRIM(p."Gender")) = 'male' THEN 1 ELSE 0 END) AS "Male_Actors",
           SUM(CASE WHEN p."Gender" IS NULL OR TRIM(p."Gender") = '' THEN 1 ELSE 0 END) AS "Unknown_Gender_Actors"
    FROM DB_IMDB.DB_IMDB."M_CAST" mc
    JOIN DB_IMDB.DB_IMDB."PERSON" p ON TRIM(mc."PID") = TRIM(p."PID")
    GROUP BY mc."MID"
) per_movie ON m."MID" = per_movie."MID"
GROUP BY m."year"
ORDER BY m."year";