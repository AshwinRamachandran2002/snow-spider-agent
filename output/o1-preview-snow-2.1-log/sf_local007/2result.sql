SELECT ROUND(AVG(career_span_years), 4) AS "Average_Career_Span_Years"
FROM (
    SELECT "player_id",
           "debut",
           "final_game",
           CASE
               WHEN total_days >= 365 THEN FLOOR(total_days / 365)
               WHEN total_days >= 30 THEN (FLOOR(total_days / 30)) / 12.0
               ELSE total_days / 365.0
           END AS career_span_years
    FROM (
        SELECT "player_id",
               "debut",
               "final_game",
               DATEDIFF('day', TO_DATE("final_game", 'YYYY-MM-DD'), TO_DATE("debut", 'YYYY-MM-DD')) AS total_days
        FROM BASEBALL.BASEBALL.PLAYER
        WHERE TRY_TO_DATE("debut", 'YYYY-MM-DD') IS NOT NULL
          AND TRY_TO_DATE("final_game", 'YYYY-MM-DD') IS NOT NULL
    ) AS sub
) AS t;