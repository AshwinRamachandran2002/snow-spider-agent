WITH non_stack_max AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS max_non_stack_test_score
    FROM "model_score"
    WHERE "step" IN (1,2,3)
      AND "model" NOT LIKE '%Stack%'
    GROUP BY "name", "version", "step"
),
stack_scores AS (
    SELECT "name",
           "version",
           "step",
           "test_score" AS stack_test_score
    FROM "model_score"
    WHERE "step" IN (1,2,3)
      AND "model" LIKE '%Stack%'
),
better_stack AS (
    SELECT ns."name",
           ns."version",
           ns."step"
    FROM non_stack_max ns
    JOIN stack_scores ss
      ON ns."name"    = ss."name"
     AND ns."version" = ss."version"
     AND ns."step"    = ss."step"
    WHERE ss.stack_test_score > ns.max_non_stack_test_score
),
better_counts AS (
    SELECT "name",
           COUNT(*) AS qual_cnt
    FROM better_stack
    GROUP BY "name"
),
solution_counts AS (
    SELECT "name",
           COUNT(*) AS sol_cnt
    FROM "solution"
    GROUP BY "name"
)
SELECT bc."name"
FROM better_counts bc
LEFT JOIN solution_counts sc
       ON bc."name" = sc."name"
WHERE bc.qual_cnt > IFNULL(sc.sol_cnt, 0);