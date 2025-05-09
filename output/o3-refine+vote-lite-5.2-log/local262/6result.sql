WITH stack_scores AS (
    SELECT 
        "name",
        "version",
        "step",
        MAX("test_score") AS stack_test_score
    FROM "model_score"
    WHERE "step" IN (1,2,3)
      AND LOWER("model") LIKE '%stack%'          -- keep only “Stack” models (any case / wording)
    GROUP BY "name","version","step"
),
non_stack_max AS (
    SELECT
        "name",
        "version",
        "step",
        MAX("test_score") AS non_stack_test_score
    FROM "model_score"
    WHERE "step" IN (1,2,3)
      AND LOWER("model") NOT LIKE '%stack%'      -- all other models
    GROUP BY "name","version","step"
),
better_stack_occurrences AS (                    -- steps where Stack outperforms every other model
    SELECT n."name"
    FROM non_stack_max n
    JOIN stack_scores s
      ON n."name"    = s."name"
     AND n."version" = s."version"
     AND n."step"    = s."step"
    WHERE n.non_stack_test_score < s.stack_test_score
),
cnt_better AS (
    SELECT "name", COUNT(*) AS cnt_better
    FROM better_stack_occurrences
    GROUP BY "name"
),
cnt_solution AS (
    SELECT "name", COUNT(*) AS cnt_solution
    FROM "solution"
    GROUP BY "name"
)
SELECT b."name"
FROM cnt_better b
JOIN cnt_solution s
  ON b."name" = s."name"
WHERE b.cnt_better > s.cnt_solution;