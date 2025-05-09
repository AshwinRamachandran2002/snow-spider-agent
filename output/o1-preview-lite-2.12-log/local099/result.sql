WITH YashChopraMovies AS (
  SELECT mc."PID" AS "ActorPID", COUNT(*) AS "MoviesWithYashChopra"
  FROM "M_Cast" mc
  INNER JOIN "M_Director" md ON mc."MID" = md."MID"
  WHERE md."PID" = 'nm0007181'
  GROUP BY mc."PID"
),
OtherDirectorMovies AS (
  SELECT sub."ActorPID", MAX(sub."MovieCount") AS "MaxMoviesWithOtherDirector"
  FROM (
    SELECT mc."PID" AS "ActorPID", md."PID" AS "DirectorPID", COUNT(*) AS "MovieCount"
    FROM "M_Cast" mc
    INNER JOIN "M_Director" md ON mc."MID" = md."MID"
    WHERE md."PID" <> 'nm0007181'
    GROUP BY mc."PID", md."PID"
  ) sub
  GROUP BY sub."ActorPID"
)
SELECT COUNT(*) AS "Number_of_Actors"
FROM YashChopraMovies yc
LEFT JOIN OtherDirectorMovies odm ON yc."ActorPID" = odm."ActorPID"
WHERE yc."MoviesWithYashChopra" > IFNULL(odm."MaxMoviesWithOtherDirector", 0);