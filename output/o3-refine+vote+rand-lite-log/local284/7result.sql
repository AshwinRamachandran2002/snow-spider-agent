WITH stats AS (
    SELECT
        AVG("loss_rate_%")                                                        AS avg_loss_rate,
        AVG("loss_rate_%"
            * "loss_rate_%") - AVG("loss_rate_%") * AVG("loss_rate_%")            AS variance
    FROM "veg_loss_rate_df"
),
categorized AS (
    SELECT
        CASE
            WHEN (v."loss_rate_%" - s.avg_loss_rate)
                 * (v."loss_rate_%" - s.avg_loss_rate) > s.variance
                 AND v."loss_rate_%" > s.avg_loss_rate           THEN 'above_sd'
            WHEN (v."loss_rate_%" - s.avg_loss_rate)
                 * (v."loss_rate_%" - s.avg_loss_rate) > s.variance
                 AND v."loss_rate_%" < s.avg_loss_rate           THEN 'below_sd'
            ELSE                                                    'within_sd'
        END AS category
    FROM "veg_loss_rate_df" v
    CROSS JOIN stats s
)
SELECT
    ROUND(s.avg_loss_rate, 4)                                              AS avg_loss_rate,
    SUM(CASE WHEN c.category = 'below_sd'  THEN 1 ELSE 0 END)              AS count_below_sd,
    SUM(CASE WHEN c.category = 'within_sd' THEN 1 ELSE 0 END)              AS count_within_sd,
    SUM(CASE WHEN c.category = 'above_sd'  THEN 1 ELSE 0 END)              AS count_above_sd
FROM categorized c
CROSS JOIN stats s;