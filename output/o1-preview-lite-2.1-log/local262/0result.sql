SELECT "traditional_model"
FROM (
    SELECT t1."model" AS traditional_model,
           SUM(CASE WHEN t1."test_score" < t2."test_score" THEN 1 ELSE 0 END) AS times_performed_worse,
           SUM(CASE WHEN t1."test_score" >= t2."test_score" THEN 1 ELSE 0 END) AS times_performed_better_or_equal
    FROM "model_score" t1
    JOIN "model_score" t2
      ON t1."name" = t2."name"
     AND t1."version" = t2."version"
     AND t1."step" = t2."step"
    WHERE t1."model" != t2."model"
      AND t2."model" LIKE '%Stack%'
      AND t1."model" NOT LIKE '%Stack%'
    GROUP BY t1."model"
) AS comparison
WHERE times_performed_worse > times_performed_better_or_equal;