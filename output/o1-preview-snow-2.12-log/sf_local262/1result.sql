WITH
Problems_with_more_occurrences_in_steps_1_2_3 AS (
  SELECT s_occurrences."name" AS "Problem_Name"
  FROM
    (SELECT sol."name", COUNT(*) AS "occurrences_in_steps_1_2_3"
     FROM "STACKING"."STACKING"."SOLUTION" sol
     JOIN "STACKING"."STACKING"."MODEL_SCORE" ms
       ON sol."name" = ms."name" AND sol."version" = ms."version"
     WHERE ms."step" IN (1, 2, 3)
     GROUP BY sol."name") s_occurrences
  LEFT JOIN
    (SELECT sol."name", COUNT(*) AS "occurrences_in_other_steps"
     FROM "STACKING"."STACKING"."SOLUTION" sol
     JOIN "STACKING"."STACKING"."MODEL_SCORE" ms
       ON sol."name" = ms."name" AND sol."version" = ms."version"
     WHERE ms."step" NOT IN (1, 2, 3)
     GROUP BY sol."name") o_occurrences
    ON s_occurrences."name" = o_occurrences."name"
  WHERE s_occurrences."occurrences_in_steps_1_2_3" > COALESCE(o_occurrences."occurrences_in_other_steps", 0)
),
Problems_where_Stack_beats_non_Stack AS (
  SELECT DISTINCT s."name" AS "Problem_Name"
  FROM
    (SELECT "name", "version", "step", "test_score"
     FROM "STACKING"."STACKING"."MODEL_SCORE"
     WHERE "model" = 'Stack' AND "step" IN (1, 2, 3)) s
  JOIN
    (SELECT "name", "version", "step", MAX("test_score") AS "max_non_stack_test_score"
     FROM "STACKING"."STACKING"."MODEL_SCORE"
     WHERE "model" != 'Stack' AND "step" IN (1, 2, 3)
     GROUP BY "name", "version", "step") ns
    ON s."name" = ns."name" AND s."version" = ns."version" AND s."step" = ns."step"
  WHERE s."test_score" > ns."max_non_stack_test_score"
)
SELECT DISTINCT p."Problem_Name"
FROM Problems_with_more_occurrences_in_steps_1_2_3 p
INNER JOIN Problems_where_Stack_beats_non_Stack s
  ON p."Problem_Name" = s."Problem_Name";