SELECT sub."status", sub."L1_model", sub."occurrences"
FROM (
    SELECT 
        status_table."status", 
        m."L1_model", 
        COUNT(*) AS "occurrences",
        ROW_NUMBER() OVER (
            PARTITION BY status_table."status" 
            ORDER BY COUNT(*) DESC NULLS LAST
        ) AS rn
    FROM "STACKING"."STACKING"."MODEL" m
    INNER JOIN (
        SELECT 
            s."name", 
            s."version", 
            s."step",
            CASE
                WHEN n."max_non_stack_test_score" < s."test_score" THEN 'strong'
                WHEN n."max_non_stack_test_score" = s."test_score" THEN 'soft'
                ELSE 'other'
            END AS "status"
        FROM "STACKING"."STACKING"."MODEL_SCORE" s
        INNER JOIN (
            SELECT 
                "name", "version", "step", 
                MAX("test_score") AS "max_non_stack_test_score"
                FROM "STACKING"."STACKING"."MODEL_SCORE"
                WHERE "model" != 'Stack'
                GROUP BY "name", "version", "step"
        ) n 
        ON s."name" = n."name" AND s."version" = n."version" AND s."step" = n."step"
        WHERE s."model" = 'Stack'
    ) status_table 
    ON m."name" = status_table."name" 
    AND m."version" = status_table."version" 
    AND m."step" = status_table."step"
    WHERE status_table."status" IN ('strong', 'soft')
    GROUP BY status_table."status", m."L1_model"
) sub
WHERE sub.rn = 1
ORDER BY sub."status";