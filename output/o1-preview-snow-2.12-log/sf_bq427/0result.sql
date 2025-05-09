SELECT
    p."shot_type",
    AVG(
        CASE
            WHEN p."team_basket" = 'left' THEN p."event_coord_x"
            ELSE 1128 - p."event_coord_x"
        END
    ) AS "avg_adjusted_x",
    AVG(
        CASE
            WHEN p."team_basket" = 'left' THEN 600 - p."event_coord_y"
            ELSE p."event_coord_y"
        END
    ) AS "avg_adjusted_y",
    COUNT(*) AS "avg_shot_attempts",
    SUM(CASE WHEN p."points_scored" > 0 THEN 1 ELSE 0 END) AS "avg_successful_shots"
FROM
    "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_PBP_SR" p
JOIN
    "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_GAMES_SR" g
    ON p."game_id" = g."game_id"
WHERE
    p."shot_type" IS NOT NULL
    AND p."event_coord_x" IS NOT NULL
    AND p."event_coord_y" IS NOT NULL
    AND g."scheduled_date" < '2018-03-15'
    AND p."team_basket" IN ('left', 'right')
    AND (
        (p."team_basket" = 'left' AND p."event_coord_x" <= 564)
        OR (p."team_basket" = 'right' AND p."event_coord_x" >= 564)
    )
GROUP BY
    p."shot_type";