WITH mean_cte AS (
    SELECT AVG("loss_rate_%") AS mean_val
    FROM "veg_loss_rate_df"
),
var_cte AS (
    SELECT 
        AVG( ("loss_rate_%" - mean_val) * ("loss_rate_%" - mean_val) ) AS var_val,
        mean_val
    FROM "veg_loss_rate_df"
    CROSS JOIN mean_cte
),
counts AS (
    SELECT
        SUM(
            CASE 
                WHEN ("loss_rate_%" - mean_val) * ("loss_rate_%" - mean_val) > var_val
                     AND "loss_rate_%" < mean_val 
                THEN 1 ELSE 0 
            END
        ) AS below_cnt,
        SUM(
            CASE 
                WHEN ("loss_rate_%" - mean_val) * ("loss_rate_%" - mean_val) > var_val
                     AND "loss_rate_%" > mean_val 
                THEN 1 ELSE 0 
            END
        ) AS above_cnt,
        SUM(
            CASE 
                WHEN ("loss_rate_%" - mean_val) * ("loss_rate_%" - mean_val) <= var_val 
                THEN 1 ELSE 0 
            END
        ) AS within_cnt
    FROM "veg_loss_rate_df"
    CROSS JOIN var_cte
),
final AS (
    SELECT 'avg_loss_rate'  AS metric, ROUND(mean_val,4) AS value FROM mean_cte
    UNION ALL
    SELECT 'count_below_1sd', below_cnt   FROM counts
    UNION ALL
    SELECT 'count_within_1sd', within_cnt FROM counts
    UNION ALL
    SELECT 'count_above_1sd', above_cnt   FROM counts
)
SELECT metric, value
FROM final
ORDER BY CASE metric
           WHEN 'avg_loss_rate'   THEN 1
           WHEN 'count_below_1sd' THEN 2
           WHEN 'count_within_1sd' THEN 3
           WHEN 'count_above_1sd' THEN 4
         END;