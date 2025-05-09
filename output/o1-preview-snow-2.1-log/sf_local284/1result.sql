WITH avg_stats AS (
  SELECT
    AVG("loss_rate_%") AS avg_loss_rate,
    STDDEV("loss_rate_%") AS std_loss_rate
  FROM
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
)
SELECT
  ROUND(avg_stats.avg_loss_rate, 4) AS "Average_Loss_Rate",
  (SELECT COUNT(*) FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v WHERE v."loss_rate_%" < avg_stats.avg_loss_rate - avg_stats.std_loss_rate) AS "Items_Below_One_Std_Dev",
  (SELECT COUNT(*) FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v WHERE v."loss_rate_%" BETWEEN avg_stats.avg_loss_rate - avg_stats.std_loss_rate AND avg_stats.avg_loss_rate + avg_stats.std_loss_rate) AS "Items_Within_One_Std_Dev",
  (SELECT COUNT(*) FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v WHERE v."loss_rate_%" > avg_stats.avg_loss_rate + avg_stats.std_loss_rate) AS "Items_Above_One_Std_Dev"
FROM
  avg_stats;