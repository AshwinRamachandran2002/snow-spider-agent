WITH stats AS (
    SELECT
        AVG("loss_rate_%") AS avg_loss_rate,
        AVG(("loss_rate_%") * ("loss_rate_%")) 
        - AVG("loss_rate_%") * AVG("loss_rate_%") AS var_loss_rate
    FROM "veg_loss_rate_df"
),
classified AS (
    SELECT
        CASE
            WHEN (v."loss_rate_%" - s.avg_loss_rate)*(v."loss_rate_%" - s.avg_loss_rate) > s.var_loss_rate
                 AND v."loss_rate_%" < s.avg_loss_rate THEN 'below_one_sd'
            WHEN (v."loss_rate_%" - s.avg_loss_rate)*(v."loss_rate_%" - s.avg_loss_rate) > s.var_loss_rate
                 AND v."loss_rate_%" > s.avg_loss_rate THEN 'above_one_sd'
            ELSE 'within_one_sd'
        END AS category
    FROM "veg_loss_rate_df" v
    CROSS JOIN stats s
)
SELECT
    (SELECT avg_loss_rate FROM stats)                                   AS average_loss_rate,
    SUM(CASE WHEN category = 'below_one_sd'  THEN 1 ELSE 0 END)         AS count_below_one_sd,
    SUM(CASE WHEN category = 'within_one_sd' THEN 1 ELSE 0 END)         AS count_within_one_sd,
    SUM(CASE WHEN category = 'above_one_sd'  THEN 1 ELSE 0 END)         AS count_above_one_sd
FROM classified;