WITH RECURSIVE numbers(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM numbers WHERE n < 20
), driver_positions AS (
  SELECT
    lp."race_id",
    lp."driver_id",
    lp."lap",
    lp."position" AS curr_position,
    LAG(lp."position") OVER (
      PARTITION BY lp."race_id", lp."driver_id"
      ORDER BY lp."lap"
    ) AS prev_position
  FROM "F1"."F1"."LAP_POSITIONS" lp
  WHERE lp."lap" BETWEEN 1 AND 5
), improvements AS (
  SELECT
    dp."race_id",
    dp."lap",
    dp."driver_id" AS driver_id_overtaker,
    dp.curr_position,
    dp.prev_position,
    dp.prev_position - dp.curr_position AS positions_gained
  FROM driver_positions dp
  WHERE dp.prev_position IS NOT NULL AND dp.curr_position < dp.prev_position
), overtaken_positions AS (
  SELECT
    imp."race_id",
    imp."lap",
    imp.driver_id_overtaker,
    imp.curr_position,
    imp.prev_position,
    imp.positions_gained,
    imp.curr_position + numbers.n AS overtaken_position
  FROM improvements imp
  JOIN numbers ON numbers.n <= imp.positions_gained
), overtakes AS (
  SELECT
    op.*,
    lp_prev."driver_id" AS driver_id_overtaken
  FROM overtaken_positions op
  JOIN "F1"."F1"."LAP_POSITIONS" lp_prev
    ON op."race_id" = lp_prev."race_id"
   AND lp_prev."lap" = op."lap" - 1
   AND lp_prev."position" = op.overtaken_position
), final_overtakes AS (
  SELECT
    o.*,
    CASE
      WHEN r_ret."driver_id" IS NOT NULL THEN 'R'
      WHEN ps."driver_id" IS NOT NULL THEN 'P'
      WHEN o."lap" = 1 AND ABS(res_overtaker."grid" - res_overtaken."grid") <= 2 THEN 'S'
      ELSE 'T'
    END AS overtake_type
  FROM overtakes o
  LEFT JOIN "F1"."F1"."RETIREMENTS" r_ret
    ON o."race_id" = r_ret."race_id"
   AND o.driver_id_overtaken = r_ret."driver_id"
   AND r_ret."lap" = o."lap"
  LEFT JOIN "F1"."F1"."PIT_STOPS" ps
    ON o."race_id" = ps."race_id"
   AND o.driver_id_overtaken = ps."driver_id"
   AND ps."lap" = o."lap"
  JOIN "F1"."F1"."RESULTS" res_overtaker
    ON o."race_id" = res_overtaker."race_id"
   AND o.driver_id_overtaker = res_overtaker."driver_id"
  JOIN "F1"."F1"."RESULTS" res_overtaken
    ON o."race_id" = res_overtaken."race_id"
   AND o.driver_id_overtaken = res_overtaken."driver_id"
)
SELECT
  overtake_type AS "Type",
  COUNT(*) AS "Number_of_Overtakes"
FROM final_overtakes
GROUP BY overtake_type
ORDER BY "Type";