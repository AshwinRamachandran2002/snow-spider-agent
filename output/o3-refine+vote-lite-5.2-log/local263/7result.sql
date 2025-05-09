WITH step_scores AS (
    /* 1.  For every (name, version, step) keep the best “Stack” score and the
           best non‑“Stack” score.                                               */
    SELECT  name,
            version,
            step,
            MAX(CASE WHEN model LIKE '%STACK%' COLLATE NOCASE
                     THEN test_score END)               AS stack_score,
            MAX(CASE WHEN model NOT LIKE '%STACK%' COLLATE NOCASE
                     THEN test_score END)               AS nonstack_score
    FROM    model_score
    GROUP BY name, version, step
    HAVING  stack_score IS NOT NULL                  /* need both kinds        */
       AND  nonstack_score IS NOT NULL
),
model_status AS (
    /* 2.  Decide whether each (name,version) is “strong” or “soft”.            */
    SELECT  s.name,
            s.version,
            CASE
                WHEN EXISTS (SELECT 1
                             FROM   step_scores x
                             WHERE  x.name    = s.name
                               AND  x.version = s.version
                               AND  x.stack_score > x.nonstack_score)
                     THEN 'strong'
                WHEN EXISTS (SELECT 1
                             FROM   step_scores x
                             WHERE  x.name    = s.name
                               AND  x.version = s.version
                               AND  x.stack_score = x.nonstack_score)
                     THEN 'soft'
            END                                                   AS status
    FROM   (SELECT DISTINCT name, version FROM step_scores) s
),
model_l1 AS (
    /* 3.  Attach the L1_model coming from the “model” table.                   */
    SELECT DISTINCT name, version, L1_model
    FROM   model
),
status_l1 AS (
    /* 4.  Keep only models whose status could be decided.                      */
    SELECT  m.status,
            l.L1_model
    FROM    model_status  m
    JOIN    model_l1      l USING (name, version)
    WHERE   m.status IS NOT NULL
),
counts AS (
    /* 5.  Count how many times each L1_model appears for every status.         */
    SELECT  status,
            L1_model,
            COUNT(*) AS cnt
    FROM    status_l1
    GROUP BY status, L1_model
),
max_counts AS (
    /* 6.  Pick the L1_model(s) with the highest count for each status.         */
    SELECT  c.status,
            c.L1_model,
            c.cnt
    FROM    counts c
    JOIN   (SELECT status, MAX(cnt) AS max_cnt
            FROM   counts
            GROUP BY status) mx
      ON  c.status = mx.status
     AND  c.cnt    = mx.max_cnt
)
SELECT  status,
        L1_model,
        cnt AS occurrences
FROM    max_counts
ORDER BY status, L1_model;