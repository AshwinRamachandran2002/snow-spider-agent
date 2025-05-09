SELECT ROUND(
         AVG(
             ROUND(ABS(CAST((julianday("final_game") - julianday("debut")) / 365 AS INTEGER)), 2)                        -- years
           + ROUND(ABS(CAST(((julianday("final_game") - julianday("debut")) % 365) / 30 AS INTEGER)) / 12.0, 2)         -- months/12
           + ROUND(ABS(CAST((julianday("final_game") - julianday("debut")) % 30 AS INTEGER)) / 365.0, 2)                -- days/365
         ), 2
       ) AS "average_career_span_years"
FROM "player"
WHERE "debut" <> '' 
  AND "final_game" <> '';