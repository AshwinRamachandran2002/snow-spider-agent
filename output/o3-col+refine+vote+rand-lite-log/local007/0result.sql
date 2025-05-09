SELECT
    ROUND(
        AVG(
            ROUND(ABS(CAST(SUBSTR("final_game",1,4) AS INTEGER) -
                      CAST(SUBSTR("debut",1,4)      AS INTEGER)), 2)
          + ROUND(ABS(CAST(SUBSTR("final_game",6,2) AS INTEGER) -
                      CAST(SUBSTR("debut",6,2)      AS INTEGER)) / 12.0, 2)
          + ROUND(ABS(CAST(SUBSTR("final_game",9,2) AS INTEGER) -
                      CAST(SUBSTR("debut",9,2)      AS INTEGER)) / 365.0, 2)
        ), 2
    ) AS average_career_span_years
FROM "player"
WHERE "debut" <> ''
  AND "final_game" <> '';