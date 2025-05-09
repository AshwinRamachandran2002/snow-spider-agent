WITH item_loss AS (
    SELECT "item_code", MAX("loss_rate_%") AS loss_rate
    FROM veg_loss_rate_df
    GROUP BY "item_code"
),
stats AS (
    SELECT
        AVG(loss_rate)                                              AS mean_lr,
        AVG(loss_rate * loss_rate) - AVG(loss_rate) * AVG(loss_rate) AS var_lr
    FROM item_loss
),
banding AS (
    SELECT
        s.mean_lr AS avg_lr,
        SUM(
            CASE
                WHEN il.loss_rate < s.mean_lr
                     AND (il.loss_rate - s.mean_lr)*(il.loss_rate - s.mean_lr) > s.var_lr
                THEN 1 ELSE 0 END
        ) AS below_cnt,
        SUM(
            CASE
                WHEN (il.loss_rate - s.mean_lr)*(il.loss_rate - s.mean_lr) <= s.var_lr
                THEN 1 ELSE 0 END
        ) AS within_cnt,
        SUM(
            CASE
                WHEN il.loss_rate > s.mean_lr
                     AND (il.loss_rate - s.mean_lr)*(il.loss_rate - s.mean_lr) > s.var_lr
                THEN 1 ELSE 0 END
        ) AS above_cnt
    FROM item_loss il
    JOIN stats s
)
SELECT 'average_loss_rate_pct' AS metric, ROUND(avg_lr,4) AS value FROM banding
UNION ALL
SELECT 'below_one_std_cnt',    below_cnt   FROM banding
UNION ALL
SELECT 'within_one_std_cnt',   within_cnt  FROM banding
UNION ALL
SELECT 'above_one_std_cnt',    above_cnt   FROM banding;