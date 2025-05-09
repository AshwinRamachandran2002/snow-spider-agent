WITH career_spans AS (
    SELECT
        ROUND(ABS(CAST(SUBSTR("final_game",1,4) AS REAL) - CAST(SUBSTR("debut",1,4) AS REAL)), 2)      -- years
      + ROUND(ABS(CAST(SUBSTR("final_game",6,2) AS REAL) - CAST(SUBSTR("debut",6,2) AS REAL)) / 12.0, 2)  -- months → years
      + ROUND(ABS(CAST(SUBSTR("final_game",9,2) AS REAL) - CAST(SUBSTR("debut",9,2) AS REAL)) / 365.0, 2) -- days → years
        AS career_span
    FROM "player"
    WHERE "debut" <> '' AND "final_game" <> ''
)
SELECT ROUND(AVG(career_span), 2) AS average_career_span_years
FROM career_spans;