WITH stats AS (
    -- mean and variance (stdev²) of loss rates
    SELECT
        AVG("loss_rate_%")                                               AS mean,
        AVG("loss_rate_%" * "loss_rate_%") 
          - AVG("loss_rate_%") * AVG("loss_rate_%")                      AS var
    FROM "veg_loss_rate_df"
),
flagged AS (
    -- label every item as below, above or within one stdev of the mean
    SELECT
        v."loss_rate_%",
        s.mean,
        s.var,
        CASE 
            WHEN v."loss_rate_%" < s.mean 
                 AND (s.mean - v."loss_rate_%") * (s.mean - v."loss_rate_%") > s.var
                 THEN 1 ELSE 0 
        END                                                             AS below_one_std,
        CASE 
            WHEN v."loss_rate_%" > s.mean 
                 AND (v."loss_rate_%" - s.mean) * (v."loss_rate_%" - s.mean) > s.var
                 THEN 1 ELSE 0 
        END                                                             AS above_one_std,
        CASE 
            WHEN (v."loss_rate_%" - s.mean) * (v."loss_rate_%" - s.mean) <= s.var
                 THEN 1 ELSE 0 
        END                                                             AS within_one_std
    FROM "veg_loss_rate_df" v
    CROSS JOIN stats s
)
SELECT
    ROUND(MAX(mean), 4)                      AS average_loss_rate,  -- same for every row
    SUM(below_one_std)                       AS below_one_std,
    SUM(above_one_std)                       AS above_one_std,
    SUM(within_one_std)                      AS within_one_std
FROM flagged;