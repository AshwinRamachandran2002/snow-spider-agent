WITH stats AS (
    SELECT
        AVG("loss_rate_%") AS avg_loss_rate,
        AVG(("loss_rate_%") * ("loss_rate_%")) 
          - AVG("loss_rate_%") * AVG("loss_rate_%") AS var_loss_rate
    FROM veg_loss_rate_df
),
categorized AS (
    SELECT
        CASE
            WHEN       ("loss_rate_%" - stats.avg_loss_rate) > 0
                 AND  ("loss_rate_%" - stats.avg_loss_rate)
                      * ("loss_rate_%" - stats.avg_loss_rate) > stats.var_loss_rate
                 THEN 'above_one_std'
            WHEN       ("loss_rate_%" - stats.avg_loss_rate) < 0
                 AND  ("loss_rate_%" - stats.avg_loss_rate)
                      * ("loss_rate_%" - stats.avg_loss_rate) > stats.var_loss_rate
                 THEN 'below_one_std'
            ELSE 'within_one_std'
        END AS category
    FROM veg_loss_rate_df
    CROSS JOIN stats
)
SELECT
    ROUND(stats.avg_loss_rate, 4)                            AS average_loss_rate,
    ROUND(stats.var_loss_rate, 4)                            AS variance_loss_rate,
    SUM(CASE WHEN category = 'below_one_std'  THEN 1 END)    AS below_one_std_count,
    SUM(CASE WHEN category = 'within_one_std' THEN 1 END)    AS within_one_std_count,
    SUM(CASE WHEN category = 'above_one_std'  THEN 1 END)    AS above_one_std_count
FROM stats, categorized;