-- Task: Using the 'VEG_LOSS_RATE_DF' table in the 'BANK_SALES_TRADING.BANK_SALES_TRADING' schema, generate a summary of items' loss rates based on the "loss_rate_%" column. Calculate the average loss rate (rounded to 4 decimal places) and provide counts of items that have a loss rate more than one standard deviation below the average, within one standard deviation of the average, and more than one standard deviation above the average.
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