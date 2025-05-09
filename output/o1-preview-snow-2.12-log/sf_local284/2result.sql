WITH stats AS (
  SELECT 
    AVG("loss_rate_%") AS avg_loss, 
    STDDEV("loss_rate_%") AS std_dev
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF"
)
SELECT 
  ROUND(stats.avg_loss, 4) AS "Average_Loss_Rate",
  (SELECT COUNT(*) 
   FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF" v 
   WHERE v."loss_rate_%" < stats.avg_loss - stats.std_dev) AS "Items_Below_One_Std_Dev",
  (SELECT COUNT(*) 
   FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF" v 
   WHERE v."loss_rate_%" BETWEEN stats.avg_loss - stats.std_dev AND stats.avg_loss + stats.std_dev) AS "Items_Within_One_Std_Dev",
  (SELECT COUNT(*) 
   FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF" v 
   WHERE v."loss_rate_%" > stats.avg_loss + stats.std_dev) AS "Items_Above_One_Std_Dev"
FROM stats;