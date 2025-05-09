WITH stats AS (
    -- ① mean (μ) & standard-deviation (σ) of all loss-rates
    SELECT 
        ROUND(AVG("loss_rate_%"), 4)                                                            AS mean_lr,
        ROUND(
            SQRT(AVG("loss_rate_%*" || "loss_rate_%") - AVG("loss_rate_%") * AVG("loss_rate_%")),
            4
        )                                                                                       AS sd_lr
    FROM "veg_loss_rate_df"
), labelled AS (
    -- ② tag each item as BELOW / WITHIN / ABOVE one σ from the mean
    SELECT
        CASE
            WHEN v."loss_rate_%" <  s.mean_lr - s.sd_lr THEN 'Below 1 SD'
            WHEN v."loss_rate_%" >  s.mean_lr + s.sd_lr THEN 'Above 1 SD'
            ELSE 'Within 1 SD'
        END AS deviation_band
    FROM "veg_loss_rate_df" AS v
    CROSS JOIN stats AS s
)
-- ③ final summary: average loss-rate and counts by deviation band
SELECT
    (SELECT mean_lr FROM stats)                                                     AS avg_loss_rate_pct,
    SUM(CASE WHEN deviation_band = 'Below 1 SD'  THEN 1 ELSE 0 END)  AS below_one_sd_count,
    SUM(CASE WHEN deviation_band = 'Within 1 SD' THEN 1 ELSE 0 END)  AS within_one_sd_count,
    SUM(CASE WHEN deviation_band = 'Above 1 SD'  THEN 1 ELSE 0 END)  AS above_one_sd_count
FROM labelled;