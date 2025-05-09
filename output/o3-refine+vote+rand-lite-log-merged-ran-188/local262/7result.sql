WITH stack_scores AS (          -- best “Stack” test‑score for each (name,version,step)
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS stack_score
    FROM   "model_score"
    WHERE  "step" IN (1,2,3)
      AND  "model" LIKE '%Stack%'          -- marks the Stack model(s)
    GROUP  BY "name","version","step"
),
nonstack_scores AS (            -- best non‑Stack test‑score for the same triplet
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS nonstack_score
    FROM   "model_score"
    WHERE  "step" IN (1,2,3)
      AND  "model" NOT LIKE '%Stack%'
    GROUP  BY "name","version","step"
),
better_stack AS (               -- keep triplets where Stack beats every non‑Stack
    SELECT s."name", s."version", s."step"
    FROM   stack_scores     s
    JOIN   nonstack_scores  n
           ON s."name"    = n."name"
          AND s."version" = n."version"
          AND s."step"    = n."step"
    WHERE  s.stack_score > n.nonstack_score
),
cnt_better AS (                 -- how many such triplets per problem
    SELECT "name", COUNT(*) AS cnt_better
    FROM   better_stack
    GROUP  BY "name"
),
cnt_solution AS (               -- how many rows the problem has in solution table
    SELECT "name", COUNT(*) AS cnt_solution
    FROM   "solution"
    GROUP  BY "name"
)
SELECT b."name"
FROM   cnt_better   b
JOIN   cnt_solution s
       ON b."name" = s."name"
WHERE  b.cnt_better > s.cnt_solution;