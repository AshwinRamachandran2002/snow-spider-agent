SELECT ROUND(AVG(
         ROUND(ABS(CAST(substr("final_game",1,4) AS INT) - CAST(substr("debut",1,4) AS INT)), 2) +
         ROUND(ABS(CAST(substr("final_game",6,2) AS INT) - CAST(substr("debut",6,2) AS INT)) / 12.0, 2) +
         ROUND(ABS(CAST(substr("final_game",9,2) AS INT) - CAST(substr("debut",9,2) AS INT)) / 365.0, 2)
       ), 2) AS avg_single_career_span_years
FROM   "player"
WHERE  "debut" <> '' 
  AND  "final_game" <> '';