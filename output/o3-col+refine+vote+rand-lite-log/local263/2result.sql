WITH perf AS (      -- compute best “Stack” vs best non-Stack test score per (name,version)
    SELECT
        "name",
        "version",
        MAX(CASE WHEN "model" LIKE '%Stack%'    THEN "test_score" END) AS stack_score,
        MAX(CASE WHEN "model" NOT LIKE '%Stack%' THEN "test_score" END) AS nonstack_max
    FROM "model_score"
    GROUP BY "name", "version"
),
status AS (         -- label each (name,version) as strong / soft when a Stack score exists
    SELECT
        "name",
        "version",
        CASE
            WHEN stack_score  > nonstack_max THEN 'strong'
            WHEN stack_score == nonstack_max THEN 'soft'
        END AS status
    FROM perf
    WHERE stack_score IS NOT NULL               -- keep only pairs that have a Stack model
),
counts AS (         -- count how many times each L1_model appears in each status
    SELECT
        s.status,
        m."L1_model",
        COUNT(*) AS occurrences
    FROM status AS s
    JOIN "model" AS m
      ON m."name" = s."name"
     AND m."version" = s."version"
    GROUP BY s.status, m."L1_model"
),
max_per_status AS ( -- find the maximum occurrence per status
    SELECT
        status,
        MAX(occurrences) AS max_occ
    FROM counts
    GROUP BY status
)
SELECT
    c.status,
    c."L1_model",
    c.occurrences
FROM counts AS c
JOIN max_per_status AS m
  ON m.status = c.status
 AND m.max_occ = c.occurrences
ORDER BY c.status, c."L1_model";