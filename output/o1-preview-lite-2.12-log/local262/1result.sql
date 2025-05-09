SELECT "model"
FROM (
    SELECT t1."model",
        SUM(CASE WHEN t1."test_score" < t2."test_score" THEN 1 ELSE 0 END) AS "times_worse",
        SUM(CASE WHEN t1."test_score" > t2."test_score" THEN 1 ELSE 0 END) AS "times_better",
        SUM(CASE WHEN t1."test_score" = t2."test_score" THEN 1 ELSE 0 END) AS "times_equal",
        COUNT(*) AS "total_times"
    FROM "model_score" t1
    JOIN "model_score" t2
        ON t1."name" = t2."name"
        AND t1."version" = t2."version"
        AND t1."step" = t2."step"
        AND t2."model" = 'Stack'
    WHERE t1."model" != 'Stack'
    GROUP BY t1."model"
) AS sub
WHERE "times_worse" > "times_better";