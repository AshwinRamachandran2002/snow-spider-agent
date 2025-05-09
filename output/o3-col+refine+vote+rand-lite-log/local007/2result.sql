SELECT ROUND(AVG(career_span),4) AS avg_career_years
FROM (
        SELECT
               ROUND( CAST(strftime('%Y', "final_game") AS INTEGER) -
                      CAST(strftime('%Y', "debut")      AS INTEGER), 2)                                       -- years
             + ROUND((CAST(strftime('%m', "final_game") AS INTEGER) -
                      CAST(strftime('%m', "debut")      AS INTEGER)) / 12.0, 2)                              -- months
             + ROUND((CAST(strftime('%d', "final_game") AS INTEGER) -
                      CAST(strftime('%d', "debut")      AS INTEGER)) / 365.0, 2)                             -- days
               AS career_span
        FROM   "player"
        WHERE  "debut" <> '' 
          AND  "final_game" <> ''
) ;