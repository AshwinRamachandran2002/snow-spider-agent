SELECT L1_model, COUNT(*) AS Total_count
FROM model
GROUP BY L1_model
ORDER BY Total_count DESC
LIMIT 1;