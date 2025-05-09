/*  Actors whose “Shahrukh‑number” = 2  */
SELECT COUNT(DISTINCT TRIM(mc_lvl2."PID")) AS shahrukh_number_2_actors
FROM   "M_Cast" AS mc_lvl2
WHERE  mc_lvl2."MID" IN (                     -- movies with any level‑1 actor
         SELECT DISTINCT mc_lvl1."MID"
         FROM   "M_Cast" AS mc_lvl1
         WHERE  TRIM(mc_lvl1."PID") IN (      -- all level‑1 actors (direct co‑actors)
                SELECT DISTINCT TRIM(mc_co."PID")
                FROM   "M_Cast" AS mc_srk
                JOIN   "M_Cast" AS mc_co
                       ON mc_srk."MID" = mc_co."MID"
                WHERE  TRIM(mc_srk."PID") = 'nm0451321'   -- Shah Rukh Khan
                  AND  TRIM(mc_co."PID")  <> 'nm0451321'
         )
       )
-- exclude Shah Rukh Khan himself
AND   TRIM(mc_lvl2."PID") <> 'nm0451321'
-- exclude all level‑1 actors (direct co‑actors)
AND   TRIM(mc_lvl2."PID") NOT IN (
         SELECT DISTINCT TRIM(mc_co."PID")
         FROM   "M_Cast" AS mc_srk
         JOIN   "M_Cast" AS mc_co
                ON mc_srk."MID" = mc_co."MID"
         WHERE  TRIM(mc_srk."PID") = 'nm0451321'
           AND  TRIM(mc_co."PID")  <> 'nm0451321'
       );