WITH valid_data AS (
    SELECT CAST("loss_rate_%" AS REAL) AS loss_rate
    FROM "veg_loss_rate_df"
    WHERE TRIM("loss_rate_%") <> '' AND "loss_rate_%" IS NOT NULL
),
stats AS (
    SELECT
        COUNT(*) AS n,
        SUM(loss_rate) AS sum_loss_rate,
        SUM(loss_rate * loss_rate) AS sum_squares,
        AVG(loss_rate) AS avg_loss_rate
    FROM valid_data
),
variance_calc AS (
    SELECT
        stats.*,
        (sum_squares - (sum_loss_rate * sum_loss_rate) / n) / (n - 1) AS variance
    FROM stats
),
categorized AS (
    SELECT
        loss_rate,
        CASE
            WHEN (loss_rate - avg_loss_rate)*(loss_rate - avg_loss_rate) < variance THEN 'within'
            WHEN loss_rate < avg_loss_rate THEN 'below'
            ELSE 'above'
        END AS deviation_category
    FROM valid_data, variance_calc
)
SELECT
    ROUND(stats.avg_loss_rate, 4) AS "Average_Loss_Rate",
    SUM(CASE WHEN deviation_category = 'below' THEN 1 ELSE 0 END) AS "Num_Items_Below_One_Std_Dev",
    SUM(CASE WHEN deviation_category = 'within' THEN 1 ELSE 0 END) AS "Num_Items_Within_One_Std_Dev",
    SUM(CASE WHEN deviation_category = 'above' THEN 1 ELSE 0 END) AS "Num_Items_Above_One_Std_Dev"
FROM
    categorized, stats;