WITH stack AS (                           -- “Stack” models’ scores
    SELECT name,
           version,
           step,
           test_score AS stack_score
    FROM   model_score
    WHERE  model LIKE '%Stack%'
),
best_non_stack AS (                       -- best NON-Stack score per step
    SELECT name,
           version,
           step,
           MAX(test_score) AS best_non_stack
    FROM   model_score
    WHERE  model NOT LIKE '%Stack%'
    GROUP  BY name, version, step
),
step_status AS (                          -- label each STEP
    SELECT s.name,
           s.version,
           s.step,
           CASE
               WHEN s.stack_score > b.best_non_stack THEN 'strong'
               WHEN s.stack_score = b.best_non_stack THEN 'soft'
           END AS status
    FROM   stack s
    JOIN   best_non_stack b
           ON  b.name    = s.name
           AND b.version = s.version
           AND b.step    = s.step
    WHERE  status IS NOT NULL
),
dataset_status AS (                       -- label each (name, version)
    SELECT name,
           version,
           CASE
               WHEN SUM(CASE WHEN status = 'strong' THEN 1 END) > 0
                    THEN 'strong'
               ELSE 'soft'
           END AS status
    FROM   step_status
    GROUP  BY name, version
),
l1_per_dataset AS (                       -- attach distinct L1_model(s)
    SELECT DISTINCT d.name,
           d.version,
           d.status,
           m.L1_model
    FROM   dataset_status d
    JOIN   model          m
           ON  m.name    = d.name
           AND m.version = d.version
),
count_per_l1 AS (                         -- count occurrences
    SELECT status,
           L1_model,
           COUNT(*) AS nb_occurrence
    FROM   l1_per_dataset
    GROUP  BY status, L1_model
),
max_per_status AS (                       -- best L1_model per status
    SELECT status,
           MAX(nb_occurrence) AS max_occ
    FROM   count_per_l1
    GROUP  BY status
)
SELECT c.status,
       c.L1_model,
       c.nb_occurrence
FROM   count_per_l1  c
JOIN   max_per_status m
       ON  m.status   = c.status
       AND m.max_occ  = c.nb_occurrence
ORDER  BY c.status;