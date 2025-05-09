SELECT
  DATE_TRUNC('month', TO_TIMESTAMP("creation_date" / 1000000))             AS "month",
  SUM(CASE WHEN "tags" ILIKE '%python%' THEN 1 ELSE 0 END)                AS "python_questions",
  COUNT(*)                                                                AS "total_questions",
  ROUND(
        SUM(CASE WHEN "tags" ILIKE '%python%' THEN 1 ELSE 0 END)
        / COUNT(*)::FLOAT , 4)                                            AS "python_share"
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "creation_date" BETWEEN 1640995200000000 AND 1672531199999999   -- 2022-01-01 to 2022-12-31 (µs epoch)
GROUP BY "month"
ORDER BY "month";