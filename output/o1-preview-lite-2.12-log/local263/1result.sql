WITH status_counts AS (
    SELECT st."status", m."L1_model", COUNT(*) AS count
    FROM
    (
        SELECT ns."name", ns."version",
               CASE
                  WHEN ns.max_non_stack_test_score < s.stack_test_score THEN 'strong'
                  WHEN ns.max_non_stack_test_score = s.stack_test_score THEN 'soft'
                  ELSE 'other'
               END AS status
        FROM
        (SELECT "name", "version", MAX("test_score") AS max_non_stack_test_score
         FROM "model_score"
         WHERE "model" <> 'Stack'
         GROUP BY "name", "version") ns
        JOIN
        (SELECT "name", "version", "test_score" AS stack_test_score
         FROM "model_score"
         WHERE "model" = 'Stack') s
        ON ns."name" = s."name" AND ns."version" = s."version"
    ) st
    JOIN
    (SELECT "name", "version", "L1_model" FROM "model" WHERE "step" = 3) m
    ON st."name" = m."name" AND st."version" = m."version"
    WHERE st."status" IN ('strong', 'soft')
    GROUP BY st."status", m."L1_model"
),
max_counts AS (
    SELECT "status", MAX(count) AS max_count
    FROM status_counts
    GROUP BY "status"
)
SELECT sc."status", sc."L1_model", sc."count"
FROM status_counts sc
JOIN max_counts mc ON sc."status" = mc."status" AND sc."count" = mc."max_count";