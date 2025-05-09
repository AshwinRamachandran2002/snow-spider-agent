WITH stack_scores AS (           -- every “Stack” model result on steps 1-3
    SELECT  "name",
            "version",
            "step",
            "test_score"         AS "stack_test_score"
    FROM    STACKING.STACKING.MODEL_SCORE
    WHERE   UPPER("model") = 'STACK'
      AND   "step" IN (1,2,3)
),
non_stack_max AS (               -- best non-Stack score on the same step/version
    SELECT  "name",
            "version",
            "step",
            MAX("test_score")    AS "max_non_stack_score"
    FROM    STACKING.STACKING.MODEL_SCORE
    WHERE   UPPER("model") <> 'STACK'
      AND   "step" IN (1,2,3)
    GROUP BY "name","version","step"
),
better_stack AS (                -- keep combinations where Stack outperforms all others
    SELECT  s."name",
            s."version",
            s."step"
    FROM    stack_scores     s
    JOIN    non_stack_max    n
           ON  s."name"    = n."name"
           AND s."version" = n."version"
           AND s."step"    = n."step"
    WHERE   n."max_non_stack_score" < s."stack_test_score"
),
occurrence_count AS (            -- how many such occurrences per problem
    SELECT  "name",
            COUNT(*) AS "occ_cnt"
    FROM    better_stack
    GROUP BY "name"
),
solution_count AS (              -- how many times each problem appears in SOLUTION
    SELECT  "name",
            COUNT(*) AS "sol_cnt"
    FROM    STACKING.STACKING.SOLUTION
    GROUP BY "name"
)
SELECT  o."name"
FROM    occurrence_count o
JOIN    solution_count  s  ON o."name" = s."name"
WHERE   o."occ_cnt" > s."sol_cnt";