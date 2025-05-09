SELECT
  p."shot_type",
  AVG(
    CASE
      WHEN p."event_coord_x" < 564 THEN p."event_coord_x"
      ELSE 1128 - p."event_coord_x"
    END
  ) AS "avg_adjusted_x",
  AVG(
    CASE
      WHEN p."event_coord_x" < 564 THEN 600 - p."event_coord_y"
      ELSE p."event_coord_y"
    END
  ) AS "avg_adjusted_y",
  AVG(pg."shot_attempts") AS "avg_shot_attempts",
  AVG(pg."successful_shots") AS "avg_successful_shots"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR p
JOIN NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR g
  ON p."game_id" = g."game_id"
JOIN (
  SELECT
    p."game_id",
    p."shot_type",
    COUNT(*) AS "shot_attempts",
    SUM(CASE WHEN p."shot_made" = TRUE THEN 1 ELSE 0 END) AS "successful_shots"
  FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR p
  JOIN NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR g
    ON p."game_id" = g."game_id"
  WHERE
    g."scheduled_date" < DATE '2018-03-15'
    AND p."shot_type" IS NOT NULL
    AND p."event_coord_x" IS NOT NULL
    AND p."event_coord_y" IS NOT NULL
    AND (
      (p."team_basket" = 'left' AND p."event_coord_x" < 564)
      OR (p."team_basket" = 'right' AND p."event_coord_x" >= 564)
    )
  GROUP BY p."game_id", p."shot_type"
) pg
  ON p."game_id" = pg."game_id" AND p."shot_type" = pg."shot_type"
WHERE
  g."scheduled_date" < DATE '2018-03-15'
  AND p."shot_type" IS NOT NULL
  AND p."event_coord_x" IS NOT NULL
  AND p."event_coord_y" IS NOT NULL
  AND (
    (p."team_basket" = 'left' AND p."event_coord_x" < 564)
    OR (p."team_basket" = 'right' AND p."event_coord_x" >= 564)
  )
GROUP BY p."shot_type"
ORDER BY p."shot_type";