SELECT ROUND(AVG(career_years), 4) AS average_career_span_years
FROM (
    SELECT
        CASE
            WHEN days_diff >= 365 THEN CAST(days_diff / 365 AS INTEGER)
            WHEN days_diff >= 30 THEN (CAST(days_diff / 30 AS INTEGER)) / 12.0
            ELSE days_diff / 365.0
        END AS career_years
    FROM (
        SELECT (julianday("final_game") - julianday("debut")) AS days_diff
        FROM "player"
        WHERE "debut" IS NOT NULL
          AND "final_game" IS NOT NULL
          AND "debut" != ''
          AND "final_game" != ''
          AND julianday("final_game") >= julianday("debut")
    )
);