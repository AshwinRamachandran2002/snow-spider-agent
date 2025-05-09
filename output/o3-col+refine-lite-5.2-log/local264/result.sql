SELECT
       CASE 
            WHEN LOWER("L1_model") LIKE '%stack%' THEN 'Stack'
            ELSE 'Traditional'
       END AS category,
       COUNT(*) AS total_occurrences
FROM "model"
GROUP BY category
ORDER BY total_occurrences DESC
LIMIT 1;