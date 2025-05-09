SELECT
  LPAD(EXTRACT(month FROM TO_TIMESTAMP_NTZ("creation_date" / 1e6))::VARCHAR, 2, '0') AS "Month_num",
  TO_CHAR(TO_TIMESTAMP_NTZ("creation_date" / 1e6), 'Month') AS "Month",
  ROUND(AVG(CASE WHEN '|' || "tags" || '|' ILIKE '%|python|%' THEN 1 ELSE 0 END), 4) AS "Proportion"
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE TO_TIMESTAMP_NTZ("creation_date" / 1e6) >= '2022-01-01' 
  AND TO_TIMESTAMP_NTZ("creation_date" / 1e6) < '2023-01-01'
GROUP BY "Month_num", "Month"
ORDER BY "Month_num";