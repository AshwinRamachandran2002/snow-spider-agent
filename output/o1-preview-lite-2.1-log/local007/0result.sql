SELECT AVG(career_span_years) AS average_career_span_years
FROM (
    SELECT
        "player_id",
        (CAST(SUBSTR("final_game", 1, 4) AS INTEGER) - CAST(SUBSTR("debut", 1, 4) AS INTEGER)) + 1 AS career_span_years
    FROM "player"
    WHERE "debut" IS NOT NULL AND "final_game" IS NOT NULL
        AND "debut" <> '' AND "final_game" <> ''
        AND JULIANDAY("final_game") >= JULIANDAY("debut")
)