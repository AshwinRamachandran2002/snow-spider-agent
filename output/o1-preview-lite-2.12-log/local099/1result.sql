SELECT COUNT(*) AS "Number_of_Actors"
FROM (
  SELECT "Actor_PID"
  FROM (
    SELECT "Actor_PID",
      MAX(CASE WHEN "Director_PID" = 'nm0007181' THEN "Movie_Count" ELSE 0 END) AS "Movies_With_Yash_Chopra",
      MAX(CASE WHEN "Director_PID" <> 'nm0007181' THEN "Movie_Count" ELSE 0 END) AS "Max_Movies_With_Other_Director"
    FROM (
      SELECT "M_Cast"."PID" AS "Actor_PID", "M_Director"."PID" AS "Director_PID", COUNT(*) AS "Movie_Count"
      FROM "M_Cast"
      INNER JOIN "M_Director" ON "M_Cast"."MID" = "M_Director"."MID"
      GROUP BY "Actor_PID", "Director_PID"
    ) AS "Counts"
    GROUP BY "Actor_PID"
  ) AS "Actor_Stats"
  WHERE "Movies_With_Yash_Chopra" > "Max_Movies_With_Other_Director" AND "Movies_With_Yash_Chopra" > 0
);