WITH
/* number of times each problem appears in the SOLUTION table */
solution_counts AS (
    SELECT
        "name",
        COUNT(*) AS solution_cnt
    FROM STACKING.STACKING.SOLUTION
    GROUP BY "name"
),

/* “Stack” models’ test-scores (steps 1-3 only)               */
stack_scores AS (
    SELECT
        "name",
        "version",
        "step",
        "test_score"        AS stack_test_score
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "step" IN (1,2,3)
      AND "model" ILIKE '%STACK%'
),

/* best non-Stack test-score per (name,version,step)           */
non_stack_scores AS (
    SELECT
        "name",
        "version",
        "step",
        MAX("test_score")   AS max_nonstack_score
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "step" IN (1,2,3)
      AND NOT ("model" ILIKE '%STACK%')
    GROUP BY "name","version","step"
),

/* occurrences where Stack beats every non-Stack model         */
stack_beats_nonstack AS (
    SELECT
        ns."name",
        ns."version",
        ns."step"
    FROM non_stack_scores  ns
    JOIN stack_scores      ss
         ON  ns."name"    = ss."name"
         AND ns."version" = ss."version"
         AND ns."step"    = ss."step"
    WHERE ns.max_nonstack_score < ss.stack_test_score
),

/* count of such favourable occurrences per problem            */
qualified_counts AS (
    SELECT
        "name",
        COUNT(*) AS qualified_cnt
    FROM stack_beats_nonstack
    GROUP BY "name"
)

/* final answer: problems whose qualified count
   exceeds their total presence in the SOLUTION table          */
SELECT
    qc."name"
FROM qualified_counts qc
JOIN solution_counts  sc
  ON qc."name" = sc."name"
WHERE qc.qualified_cnt > sc.solution_cnt;