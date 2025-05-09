WITH stats AS (
  SELECT
    AVG("loss_rate_%") AS avg_loss_rate,
    STDDEV("loss_rate_%") AS std_dev_loss_rate
  FROM
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
  WHERE
    "loss_rate_%" > 0 AND "loss_rate_%" IS NOT NULL
),
data AS (
  SELECT
    v."item_code",
    v."item_name",
    v."loss_rate_%",
    stats.avg_loss_rate,
    stats.std_dev_loss_rate
  FROM
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v,
    stats
  WHERE
    v."loss_rate_%" > 0 AND v."loss_rate_%" IS NOT NULL
)
SELECT
  ROUND(MAX(data.avg_loss_rate), 4) AS "Average_Loss_Rate",
  SUM(CASE WHEN data."loss_rate_%" < (data.avg_loss_rate - data.std_dev_loss_rate) THEN 1 ELSE 0 END) AS "Items_Below_One_Std_Dev",
  SUM(CASE WHEN data."loss_rate_%" BETWEEN (data.avg_loss_rate - data.std_dev_loss_rate) AND (data.avg_loss_rate + data.std_dev_loss_rate) THEN 1 ELSE 0 END) AS "Items_Within_One_Std_Dev",
  SUM(CASE WHEN data."loss_rate_%" > (data.avg_loss_rate + data.std_dev_loss_rate) THEN 1 ELSE 0 END) AS "Items_Above_One_Std_Dev"
FROM data;