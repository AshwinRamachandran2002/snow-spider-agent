SELECT
    AVG(
        CASE
            WHEN (julianday("final_game") - julianday("debut")) >= 365 THEN
                CAST((julianday("final_game") - julianday("debut")) / 365 AS INTEGER)
            WHEN (julianday("final_game") - julianday("debut")) >= 30 THEN
                (CAST((julianday("final_game") - julianday("debut")) / 30 AS INTEGER)) / 12.0
            ELSE
                (julianday("final_game") - julianday("debut")) / 365.0
        END
    ) AS "average_career_span_years"
FROM "player"
WHERE
    "debut" IS NOT NULL AND "debut" != ''
    AND "final_game" IS NOT NULL AND "final_game" != '';