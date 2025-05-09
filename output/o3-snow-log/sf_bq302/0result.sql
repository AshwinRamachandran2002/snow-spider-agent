SELECT
  TO_CHAR(
      DATE_TRUNC('month', TO_TIMESTAMP("creation_date" / 1000000)),
      'YYYY-MM'
  ) AS "month",
  ROUND(
    AVG(
      CASE
        WHEN "tags" = 'python'
          OR "tags" LIKE 'python|%'
          OR "tags" LIKE '%|python|%'
          OR "tags" LIKE '%|python'
        THEN 1.0 ELSE 0.0
      END
    ),
    4
  ) AS "python_proportion"
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "creation_date" >= 1640995200000000   -- 2022-01-01 (µs)
  AND "creation_date" < 1672531200000000    -- 2023-01-01 (µs)
GROUP BY 1
ORDER BY 1
LIMIT 20;