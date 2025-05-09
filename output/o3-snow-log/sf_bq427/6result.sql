WITH events_filtered AS (
    SELECT
        "shot_type",
        "event_coord_x",
        "event_coord_y",
        CASE 
            WHEN "event_coord_x" < 564 THEN "event_coord_x"
            ELSE 1128 - "event_coord_x"
        END                                                   AS "adj_x",
        CASE 
            WHEN "event_coord_x" < 564 THEN 600 - "event_coord_y"
            ELSE "event_coord_y"
        END                                                   AS "adj_y",
        "shot_made",
        "game_id"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "shot_type"            IS NOT NULL
      AND "event_coord_x"        IS NOT NULL
      AND "event_coord_y"        IS NOT NULL
      -- keep only shots on the offensive basket side
      AND (
              ("team_basket" = 'left'  AND "event_coord_x" < 564)
           OR ("team_basket" = 'right' AND "event_coord_x" >= 564)
      )
      -- only games before 15-Mar-2018 00:00:00 (epoch-µs = 1 521 072 000 000 000)
      AND "scheduled_date" < 1521072000000000
),
coord_stats AS (
    SELECT
        "shot_type",
        AVG("adj_x") AS "avg_x",
        AVG("adj_y") AS "avg_y"
    FROM events_filtered
    GROUP BY "shot_type"
),
game_stats AS (
    SELECT
        "shot_type",
        "game_id",
        COUNT(*)                                              AS "attempts",
        SUM(CASE WHEN "shot_made" THEN 1 ELSE 0 END)         AS "made"
    FROM events_filtered
    GROUP BY "shot_type", "game_id"
),
avg_game_stats AS (
    SELECT
        "shot_type",
        AVG("attempts") AS "avg_attempts",
        AVG("made")     AS "avg_made"
    FROM game_stats
    GROUP BY "shot_type"
)
SELECT
    c."shot_type",
    c."avg_x",
    c."avg_y",
    a."avg_attempts",
    a."avg_made"
FROM coord_stats      c
JOIN avg_game_stats   a ON a."shot_type" = c."shot_type"
ORDER BY c."shot_type";