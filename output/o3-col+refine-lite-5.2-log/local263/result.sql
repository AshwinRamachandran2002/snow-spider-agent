WITH non_stack AS (               -- best non‑Stack score per (name,version,step)
    SELECT "name","version","step",
           MAX("test_score") AS max_non_stack
    FROM "model_score"
    WHERE "model" NOT LIKE '%Stack%'
    GROUP BY "name","version","step"
),
stack AS (                        -- Stack score per (name,version,step)
    SELECT "name","version","step",
           "test_score" AS stack_test_score
    FROM "model_score"
    WHERE "model" LIKE '%Stack%'
),
status AS (                       -- tag every step as strong / soft
    SELECT s."name", s."version", s."step",
           CASE
               WHEN s.stack_test_score  > n.max_non_stack THEN 'strong'
               WHEN s.stack_test_score =  n.max_non_stack THEN 'soft'
           END AS status
    FROM stack s
    JOIN non_stack n
      ON n."name"    = s."name"
     AND n."version" = s."version"
     AND n."step"    = s."step"
),
l1 AS (                           -- attach L1_model to each (name,version,step,status)
    SELECT st.status,
           m."L1_model"
    FROM status st
    JOIN "model" m
      ON m."name"    = st."name"
     AND m."version" = st."version"
     AND m."step"    = st."step"
    WHERE st.status IS NOT NULL
),
cnts AS (                         -- count occurrences of each L1_model for every status
    SELECT "L1_model",
           status,
           COUNT(*) AS cnt
    FROM l1
    GROUP BY "L1_model", status
)
SELECT c.status,
       c."L1_model",
       c.cnt
FROM cnts c
JOIN (
      SELECT status,
             MAX(cnt) AS max_cnt
      FROM cnts
      GROUP BY status
     ) mx
  ON mx.status  = c.status
 AND mx.max_cnt = c.cnt          -- keep the most frequent L1_model per status
ORDER BY c.status;