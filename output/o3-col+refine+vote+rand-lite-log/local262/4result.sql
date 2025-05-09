WITH stack AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS stack_score
    FROM "model_score"
    WHERE LOWER("model") LIKE '%stack%'
    GROUP BY "name", "version", "step"
),
nonstack AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS nonstack_score
    FROM "model_score"
    WHERE LOWER("model") NOT LIKE '%stack%'
    GROUP BY "name", "version", "step"
),
stack_wins AS (
    SELECT s."name",
           s."version",
           s."step"
    FROM   stack s
    LEFT JOIN nonstack n
           ON  s."name"    = n."name"
           AND s."version" = n."version"
           AND s."step"    = n."step"
    WHERE  n.nonstack_score IS NULL
       OR  s.stack_score > n.nonstack_score
),
cnt_stack_wins AS (
    SELECT "name",
           COUNT(*) AS wins
    FROM   stack_wins
    GROUP  BY "name"
),
cnt_solution AS (
    SELECT "name",
           COUNT(*) AS sol_rows
    FROM   "solution"
    GROUP  BY "name"
)
SELECT sw."name"
FROM   cnt_stack_wins sw
JOIN   cnt_solution  so USING ("name")
WHERE  sw.wins > so.sol_rows;