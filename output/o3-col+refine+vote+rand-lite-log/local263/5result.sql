WITH
/* 1. Best “Stack” score per (name, version) */
stack_scores AS (
    SELECT "name",
           "version",
           MAX("test_score") AS stack_score
    FROM   "model_score"
    WHERE  "model" LIKE '%Stack%'
    GROUP  BY "name", "version"
),
/* 2. Best NON-“Stack” score per (name, version) */
nonstack_scores AS (
    SELECT "name",
           "version",
           MAX("test_score") AS nonstack_score
    FROM   "model_score"
    WHERE  "model" NOT LIKE '%Stack%'
    GROUP  BY "name", "version"
),
/* 3. Assign a status to every (name, version) */
status AS (
    SELECT s."name",
           s."version",
           CASE
             WHEN n.nonstack_score <  s.stack_score THEN 'strong'
             WHEN n.nonstack_score = s.stack_score THEN 'soft'
           END AS status
    FROM   stack_scores AS s
    JOIN   nonstack_scores AS n
           ON  s."name" = n."name"
           AND s."version" = n."version"
),
/* 4. One representative L1_model for each (name, version) */
l1_model AS (
    SELECT "name",
           "version",
           MIN("L1_model") AS L1_model
    FROM   "model"
    GROUP  BY "name", "version"
),
/* 5. Count how many times each L1_model appears within each status */
status_counts AS (
    SELECT st.status,
           l.L1_model,
           COUNT(*) AS occurrences
    FROM   status       AS st
    JOIN   l1_model     AS l
           ON  st."name"    = l."name"
           AND st."version" = l."version"
    WHERE  st.status IN ('strong','soft')
    GROUP  BY st.status, l.L1_model
),
/* 6. Rank L1_models by frequency within each status */
ranked AS (
    SELECT status,
           L1_model,
           occurrences,
           RANK() OVER (PARTITION BY status ORDER BY occurrences DESC) AS rnk
    FROM   status_counts
)
/* 7. Keep only the most frequent L1_model for each status */
SELECT status,
       L1_model,
       occurrences
FROM   ranked
WHERE  rnk = 1
ORDER  BY status;