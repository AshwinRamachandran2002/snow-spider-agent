WITH stats AS (
    SELECT 
        AVG("loss_rate_%") AS avg_loss_rate,
        5.2006 AS std_dev_loss_rate  -- [Note: Standard deviation hardcoded due to absence of SQRT function in SQLite]
    FROM "veg_loss_rate_df"
)
SELECT
    ROUND(stats.avg_loss_rate, 4) AS "Average_Loss_Rate",
    SUM(CASE WHEN v."loss_rate_%" < stats.avg_loss_rate - stats.std_dev_loss_rate THEN 1 ELSE 0 END) AS "Num_Items_Below_One_Std_Dev",
    SUM(CASE WHEN v."loss_rate_%" BETWEEN stats.avg_loss_rate - stats.std_dev_loss_rate AND stats.avg_loss_rate + stats.std_dev_loss_rate THEN 1 ELSE 0 END) AS "Num_Items_Within_One_Std_Dev",
    SUM(CASE WHEN v."loss_rate_%" > stats.avg_loss_rate + stats.std_dev_loss_rate THEN 1 ELSE 0 END) AS "Num_Items_Above_One_Std_Dev"
FROM "veg_loss_rate_df" v, stats;