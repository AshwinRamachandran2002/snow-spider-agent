WITH nonstack_max AS (           -- best test score among NON “Stack” models
    SELECT
        name,
        version,
        step,
        MAX(test_score) AS max_non_stack
    FROM model_score
    WHERE model NOT LIKE '%Stack%'            -- exclude “Stack” models
      AND step IN (1,2,3)                     -- only steps 1‑3
    GROUP BY name, version, step
),
stack_score AS (                 -- test score of the “Stack” model
    SELECT
        name,
        version,
        step,
        MAX(test_score) AS stack_score        -- in case several “Stack” rows exist
    FROM model_score
    WHERE model LIKE '%Stack%'                -- keep only “Stack” models
      AND step IN (1,2,3)
    GROUP BY name, version, step
),
better_stack AS (                -- steps where “Stack” beats every non‑stack model
    SELECT ns.name, ns.version, ns.step
    FROM nonstack_max ns
    JOIN stack_score  ss
          ON ns.name    = ss.name
         AND ns.version = ss.version
         AND ns.step    = ss.step
    WHERE ns.max_non_stack < ss.stack_score
),
cnt_better AS (                  -- how many such occurrences per problem
    SELECT name, COUNT(*) AS better_cnt
    FROM better_stack
    GROUP BY name
),
cnt_solution AS (                -- how many rows each problem has in solution table
    SELECT name, COUNT(*) AS sol_cnt
    FROM solution
    GROUP BY name
)
SELECT cb.name
FROM cnt_better  cb
JOIN cnt_solution cs USING (name)
WHERE cb.better_cnt > cs.sol_cnt;   -- problems that exceed their occurrences in solution