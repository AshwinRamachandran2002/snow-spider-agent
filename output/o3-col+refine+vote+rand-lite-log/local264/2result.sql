SELECT
    CASE 
        WHEN "L1_model" = 'Stack' THEN 'Stack'
        ELSE 'Traditional'
    END AS model_category,
    COUNT(*) AS total_count
FROM "model"
GROUP BY model_category
ORDER BY total_count DESC
LIMIT 1;