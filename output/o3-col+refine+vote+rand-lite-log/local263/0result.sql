WITH best_scores AS (
    -- Best “Stack” and non-“Stack” score per dataset version
    SELECT  ms."name",
            ms."version",
            MAX(CASE WHEN ms."model" LIKE '%Stack%'     THEN ms."test_score" END) AS stack_test,
            MAX(CASE WHEN ms."model" NOT LIKE '%Stack%' THEN ms."test_score" END) AS non_stack_test
    FROM    "model_score" ms
    GROUP BY ms."name", ms."version"
),
status_flag AS (
    -- Label each (name,version) as ‘strong’ / ‘soft’
    SELECT  bs."name",
            bs."version",
            CASE
                 WHEN bs.stack_test > bs.non_stack_test THEN 'strong'
                 WHEN bs.stack_test = bs.non_stack_test THEN 'soft'
            END AS status
    FROM   best_scores bs
    WHERE  bs.stack_test IS NOT NULL          -- keep only datasets that have a Stack model
),
l1_pairs AS (
    -- Attach the L1_model family to every (name,version,status)
    SELECT DISTINCT
           sf."status",
           m."L1_model"
    FROM   status_flag sf
    JOIN   "model" m
      ON   m."name"    = sf."name"
     AND   m."version" = sf."version"
    WHERE  sf.status IS NOT NULL              -- ignore cases where neither strong nor soft
),
counts AS (
    -- How many times each L1_model appears within each status
    SELECT  l1."status",
            l1."L1_model",
            COUNT(*) AS occurrences
    FROM    l1_pairs l1
    GROUP BY l1."status", l1."L1_model"
),
max_per_status AS (
    -- Highest occurrence per status
    SELECT  "status",
            MAX(occurrences) AS max_occ
    FROM    counts
    GROUP BY "status"
)
SELECT  c."status",
        c."L1_model",
        c.occurrences
FROM    counts c
JOIN    max_per_status m
  ON    c."status" = m."status"
 AND    c.occurrences = m.max_occ
ORDER BY c."status";