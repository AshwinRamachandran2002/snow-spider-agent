WITH filtered_shots AS (
    SELECT
        game_id,
        shot_type,
        shot_made,
        -- adjust X
        CASE
            WHEN event_coord_x < 564 THEN event_coord_x
            ELSE 1128 - event_coord_x
        END AS adj_x,
        -- adjust Y
        CASE
            WHEN event_coord_x < 564 THEN 600 - event_coord_y
            ELSE event_coord_y
        END AS adj_y
    FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
    WHERE
        DATE(scheduled_date) < '2018-03-15'                              -- before 15‑Mar‑2018
        AND shot_type IS NOT NULL                                         -- known shot type
        AND event_coord_x IS NOT NULL AND event_coord_y IS NOT NULL       -- known coords
        -- keep only shots on the side the team is attacking
        AND (
              (team_basket = 'left'  AND event_coord_x <  564) OR
              (team_basket = 'right' AND event_coord_x >= 564)
            )
),
per_game AS (   -- one row per game & shot type
    SELECT
        game_id,
        shot_type,
        COUNT(*)                                           AS attempts,
        SUM(CASE WHEN shot_made THEN 1 ELSE 0 END)        AS makes,
        AVG(adj_x)                                         AS avg_x_game,
        AVG(adj_y)                                         AS avg_y_game
    FROM filtered_shots
    GROUP BY game_id, shot_type
)
SELECT
    shot_type,
    AVG(avg_x_game)  AS avg_x,            -- average adjusted X
    AVG(avg_y_game)  AS avg_y,            -- average adjusted Y
    AVG(attempts)    AS avg_attempts,     -- average attempts per game
    AVG(makes)       AS avg_makes         -- average made shots per game
FROM per_game
GROUP BY shot_type
ORDER BY shot_type;