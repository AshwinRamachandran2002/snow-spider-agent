WITH filtered_shots AS (
    SELECT
        "shot_type",
        -- adjust X coordinate to a single-basket perspective
        CASE
            WHEN "event_coord_x" < 564 THEN "event_coord_x"
            ELSE 1128 - "event_coord_x"
        END                                                   AS adj_x,
        -- adjust Y coordinate correspondingly
        CASE
            WHEN "event_coord_x" < 564 THEN 600 - "event_coord_y"
            ELSE "event_coord_y"
        END                                                   AS adj_y,
        "game_id",
        "shot_made"::BOOLEAN                                   AS shot_made
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE
          "scheduled_date" < 1521072000000000          -- before 2018-03-15 (µs epoch)
      AND "shot_type" IS NOT NULL
      AND "event_coord_x" IS NOT NULL
      AND "event_coord_y" IS NOT NULL
      -- keep only shots taken at the basket the team is attacking
      AND (
              ("team_basket" = 'left'  AND "event_coord_x" < 564)
           OR ("team_basket" = 'right' AND "event_coord_x" >= 564)
          )
),

-- average adjusted coordinates per shot type
coord_avgs AS (
    SELECT
        "shot_type",
        AVG(adj_x) AS avg_x,
        AVG(adj_y) AS avg_y
    FROM filtered_shots
    GROUP BY "shot_type"
),

-- per-game totals for each shot type
game_totals AS (
    SELECT
        "shot_type",
        "game_id",
        COUNT(*)                                   AS attempts,
        SUM(CASE WHEN shot_made THEN 1 ELSE 0 END) AS made
    FROM filtered_shots
    GROUP BY "shot_type", "game_id"
),

-- average attempts & makes (per game) for each shot type
attempt_avgs AS (
    SELECT
        "shot_type",
        AVG(attempts) AS avg_attempts,
        AVG(made)     AS avg_made
    FROM game_totals
    GROUP BY "shot_type"
)

SELECT
    c."shot_type",
    c.avg_x,
    c.avg_y,
    a.avg_attempts,
    a.avg_made
FROM coord_avgs   c
JOIN attempt_avgs a
  ON c."shot_type" = a."shot_type"
ORDER BY c."shot_type";