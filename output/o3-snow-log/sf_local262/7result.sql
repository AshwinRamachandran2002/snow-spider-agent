WITH stack_scores AS (                       -- test score of Stack models
    SELECT  "name",
            "version",
            "step",
            MAX("test_score") AS stack_test_score
    FROM    STACKING.STACKING.MODEL_SCORE
    WHERE   UPPER("model") = 'STACK'
      AND   "step" IN (1,2,3)
    GROUP BY "name","version","step"
),
non_stack_scores AS (                        -- best test score of all non-Stack models
    SELECT  "name",
            "version",
            "step",
            MAX("test_score") AS non_stack_test_score
    FROM    STACKING.STACKING.MODEL_SCORE
    WHERE   UPPER("model") <> 'STACK'
      AND   "step" IN (1,2,3)
    GROUP BY "name","version","step"
),
qualifying AS (                              -- triples where Stack outperforms every non-Stack
    SELECT  s."name",
            s."version",
            s."step"
    FROM    stack_scores s
    JOIN    non_stack_scores n
           ON  s."name"    = n."name"
           AND s."version" = n."version"
           AND s."step"    = n."step"
    WHERE   s.stack_test_score > n.non_stack_test_score
),
qualifying_count AS (                        -- number of such triples per problem
    SELECT  "name",
            COUNT(*) AS qualifying_occurrences
    FROM    qualifying
    GROUP BY "name"
),
solution_count AS (                          -- how many times each problem appears in SOLUTION
    SELECT  "name",
            COUNT(*) AS solution_occurrences
    FROM    STACKING.STACKING.SOLUTION
    GROUP BY "name"
)
SELECT  q."name"
FROM    qualifying_count q
LEFT JOIN solution_count s
       ON q."name" = s."name"
WHERE   q.qualifying_occurrences > COALESCE(s.solution_occurrences,0);