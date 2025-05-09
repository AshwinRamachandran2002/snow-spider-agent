SELECT COUNT(*) AS "Number_of_Actors"
FROM (
    SELECT "Actor_PID"
    FROM (
        SELECT "Actor_PID",
               SUM(CASE WHEN "Director_PID" = 'nm0007181' THEN "Movie_Count" ELSE 0 END) AS "Yash_Count",
               MAX(CASE WHEN "Director_PID" != 'nm0007181' THEN "Movie_Count" ELSE NULL END) AS "Max_Other_Count"
        FROM (
            SELECT A."PID" AS "Actor_PID", D."PID" AS "Director_PID", COUNT(*) AS "Movie_Count"
            FROM "M_Cast" A
            JOIN "M_Director" D ON A."MID" = D."MID"
            GROUP BY A."PID", D."PID"
        ) AS ActorDirectorCounts
        GROUP BY "Actor_PID"
    ) AS ADC
    WHERE "Yash_Count" > IFNULL("Max_Other_Count", 0)
) AS Result;