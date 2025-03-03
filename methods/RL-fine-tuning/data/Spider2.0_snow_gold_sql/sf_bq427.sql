WITH shot_data AS (
    SELECT
        p."game_id",
        p."shot_type",
        CASE
            WHEN p."event_coord_x" < 564 THEN p."event_coord_x"
            ELSE 1128 - p."event_coord_x"
        END AS "adjusted_x",
        CASE
            WHEN p."event_coord_x" < 564 THEN 600 - p."event_coord_y"
            ELSE p."event_coord_y"
        END AS "adjusted_y",
        p."shot_made"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR" p
    INNER JOIN NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_GAMES_SR" g
        ON p."game_id" = g."game_id"
    WHERE
        p."shot_type" IS NOT NULL
        AND p."event_coord_x" IS NOT NULL
        AND p."event_coord_y" IS NOT NULL
        AND g."scheduled_date" < '2018-03-15'
        AND (
            (p."event_coord_x" < 564 AND p."team_basket" = 'left')
            OR
            (p."event_coord_x" >= 564 AND p."team_basket" = 'right')
        )
),
coordinate_avgs AS (
    SELECT
        "shot_type",
        ROUND(AVG("adjusted_x"), 4) AS "avg_adjusted_x",
        ROUND(AVG("adjusted_y"), 4) AS "avg_adjusted_y"
    FROM shot_data
    GROUP BY "shot_type"
),
per_game_stats AS (
    SELECT
        "shot_type",
        "game_id",
        COUNT(*) AS "shot_attempts",
        SUM(CASE WHEN "shot_made" = TRUE THEN 1 ELSE 0 END) AS "successful_shots"
    FROM shot_data
    GROUP BY "shot_type", "game_id"
),
avg_shot_stats AS (
    SELECT
        "shot_type",
        ROUND(AVG("shot_attempts"), 4) AS "avg_shot_attempts",
        ROUND(AVG("successful_shots"), 4) AS "avg_successful_shots"
    FROM per_game_stats
    GROUP BY "shot_type"
)
SELECT
    c."shot_type",
    c."avg_adjusted_x",
    c."avg_adjusted_y",
    a."avg_shot_attempts",
    a."avg_successful_shots"
FROM coordinate_avgs c
JOIN avg_shot_stats a ON c."shot_type" = a."shot_type"
ORDER BY c."shot_type";