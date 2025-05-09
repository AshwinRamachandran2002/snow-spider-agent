WITH stats AS (
    SELECT
        AVG(l."loss_rate_%") AS avg_rate,
        (AVG(l."loss_rate_%" * l."loss_rate_%")
         - AVG(l."loss_rate_%") * AVG(l."loss_rate_%")) AS var_rate
    FROM "veg_loss_rate_df" l
    WHERE l."item_code" IN (SELECT DISTINCT "item_code" FROM "veg_whsle_df")
),
classified AS (
    SELECT
        l."item_code",
        CASE
            WHEN ((l."loss_rate_%" - s.avg_rate) * (l."loss_rate_%" - s.avg_rate)) <= s.var_rate
                 THEN 'within'
            WHEN l."loss_rate_%" < s.avg_rate THEN 'below'
            ELSE 'above'
        END AS band
    FROM "veg_loss_rate_df" l
    JOIN stats s
    WHERE l."item_code" IN (SELECT DISTINCT "item_code" FROM "veg_whsle_df")
),
summary AS (
    SELECT 'average_loss_rate' AS metric, ROUND(s.avg_rate, 4) AS value FROM stats s
    UNION ALL
    SELECT 'cnt_below_1sd',  COUNT(*) FROM classified WHERE band = 'below'
    UNION ALL
    SELECT 'cnt_within_1sd', COUNT(*) FROM classified WHERE band = 'within'
    UNION ALL
    SELECT 'cnt_above_1sd',  COUNT(*) FROM classified WHERE band = 'above'
)
SELECT metric, value
FROM summary;