WITH step_scores AS (          -- collect, for every problem/version/step (1‑3), the
    SELECT                     -- best “Stack” test score and the best non‑Stack score
        name,
        version,
        step,
        MAX(CASE WHEN LOWER(model) = 'stack'      THEN test_score END) AS stack_score,
        MAX(CASE WHEN LOWER(model) <> 'stack'     THEN test_score END) AS non_stack_max
    FROM model_score
    WHERE step IN (1,2,3)
    GROUP BY name, version, step
),
better_stack AS (              -- keep only steps where Stack beats every non‑Stack model
    SELECT name, version, step
    FROM   step_scores
    WHERE  stack_score IS NOT NULL
       AND non_stack_max IS NOT NULL
       AND non_stack_max < stack_score
),
cnt_better AS (                -- count such (version,step) occurrences per problem
    SELECT name, COUNT(*) AS nb_better
    FROM   better_stack
    GROUP BY name
),
cnt_solution AS (              -- count how many times each problem appears in solution
    SELECT name, COUNT(*) AS nb_solution
    FROM   solution
    GROUP BY name
)
SELECT cb.name
FROM   cnt_better   cb
JOIN   cnt_solution cs USING (name)
WHERE  cb.nb_better > cs.nb_solution;