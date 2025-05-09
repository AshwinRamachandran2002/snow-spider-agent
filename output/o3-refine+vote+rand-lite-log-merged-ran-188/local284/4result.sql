WITH stats AS (
    /* calculate the mean and the variance (σ²) of the loss rates           */
    /* – we avoid SQRT because it is not available in this SQLite environment */
    SELECT
        AVG("loss_rate_%") AS avg_loss_rate,
        AVG("loss_rate_%" * "loss_rate_%") 
          - AVG("loss_rate_%") * AVG("loss_rate_%") AS variance
    FROM "veg_loss_rate_df"
),
categorized AS (
    /* put every item into a bucket:                                         */
    /*  • ‘within’  → |x‑μ|²  ≤ σ²                                            */
    /*  • ‘below’   → x < μ  AND |x‑μ|² > σ²                                 */
    /*  • ‘above’   → x > μ  AND |x‑μ|² > σ²                                 */
    SELECT
        CASE
            WHEN v."loss_rate_%" < s.avg_loss_rate
                 AND (s.avg_loss_rate - v."loss_rate_%")
                     * (s.avg_loss_rate - v."loss_rate_%") > s.variance
                 THEN 'below'
            WHEN v."loss_rate_%" > s.avg_loss_rate
                 AND (v."loss_rate_%" - s.avg_loss_rate)
                     * (v."loss_rate_%" - s.avg_loss_rate) > s.variance
                 THEN 'above'
            ELSE 'within'
        END AS category
    FROM "veg_loss_rate_df" v
    CROSS JOIN stats s
)
SELECT
    (SELECT avg_loss_rate FROM stats)                                  AS avg_loss_rate,
    SUM(CASE WHEN category = 'below'  THEN 1 ELSE 0 END)              AS count_below_one_sd,
    SUM(CASE WHEN category = 'within' THEN 1 ELSE 0 END)              AS count_within_one_sd,
    SUM(CASE WHEN category = 'above'  THEN 1 ELSE 0 END)              AS count_above_one_sd
FROM categorized;