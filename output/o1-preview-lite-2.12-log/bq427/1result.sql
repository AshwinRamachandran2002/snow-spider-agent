SELECT
    shot_type,
    ROUND(AVG(
        CASE
            WHEN event_coord_x < 564 THEN event_coord_x
            ELSE 1128 - event_coord_x
        END
    ), 4) AS avg_adjusted_x_coordinate,
    ROUND(AVG(
        CASE
            WHEN event_coord_x < 564 THEN 600 - event_coord_y
            ELSE event_coord_y
        END
    ), 4) AS avg_adjusted_y_coordinate,
    ROUND(COUNT(*) / COUNT(DISTINCT game_id), 4) AS avg_shot_attempts,
    ROUND(SUM(CASE WHEN shot_made = TRUE THEN 1 ELSE 0 END) / COUNT(DISTINCT game_id), 4) AS avg_successful_shots
FROM
    `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
WHERE
    shot_type IS NOT NULL
    AND event_coord_x IS NOT NULL
    AND event_coord_y IS NOT NULL
    AND scheduled_date < '2018-03-15'
    AND (
        (team_basket = 'left' AND event_coord_x < 564)
        OR (team_basket = 'right' AND event_coord_x >= 564)
    )
GROUP BY
    shot_type;