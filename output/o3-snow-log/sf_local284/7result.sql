WITH stats AS (
    SELECT
        AVG("loss_rate_%")            AS avg_loss_rate,
        STDDEV_SAMP("loss_rate_%")    AS std_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
),
categorized AS (
    SELECT
        v."item_code",
        v."loss_rate_%"                                       AS loss_rate,
        CASE
            WHEN v."loss_rate_%" <  s.avg_loss_rate - s.std_loss_rate THEN 'below'
            WHEN v."loss_rate_%" >  s.avg_loss_rate + s.std_loss_rate THEN 'above'
            ELSE 'within'
        END                                                  AS category
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v
    CROSS JOIN stats s
)
SELECT
    (SELECT avg_loss_rate FROM stats)                           AS average_loss_rate,
    SUM(CASE WHEN category = 'below'  THEN 1 ELSE 0 END)        AS items_below_one_std,
    SUM(CASE WHEN category = 'within' THEN 1 ELSE 0 END)        AS items_within_one_std,
    SUM(CASE WHEN category = 'above'  THEN 1 ELSE 0 END)        AS items_above_one_std
FROM categorized;