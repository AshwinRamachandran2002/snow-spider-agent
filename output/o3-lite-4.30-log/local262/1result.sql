WITH non_stack AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS max_non_stack
    FROM "model_score"
    WHERE "model" NOT LIKE '%Stack%'
      AND "step" IN (1,2,3)
    GROUP BY "name", "version", "step"
),
stack AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS stack_test
    FROM "model_score"
    WHERE "model" LIKE '%Stack%'
      AND "step" IN (1,2,3)
    GROUP BY "name", "version", "step"
),
outperform_steps AS (
    SELECT ns."name",
           ns."version",
           ns."step"
    FROM non_stack ns
    JOIN stack st
      ON ns."name"    = st."name"
     AND ns."version" = st."version"
     AND ns."step"    = st."step"
    WHERE st.stack_test > ns.max_non_stack
),
outperform_count AS (
    SELECT "name",
           COUNT(*) AS outperform_cnt
    FROM outperform_steps
    GROUP BY "name"
),
solution_count AS (
    SELECT "name",
           COUNT(*) AS solution_cnt
    FROM "solution"
    GROUP BY "name"
)
SELECT DISTINCT oc."name" AS problem
FROM outperform_count oc
LEFT JOIN solution_count sc
       ON oc."name" = sc."name"
WHERE oc.outperform_cnt > COALESCE(sc.solution_cnt, 0);