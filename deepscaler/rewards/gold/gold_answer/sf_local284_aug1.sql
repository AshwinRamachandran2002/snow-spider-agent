-- Task: Compute the average and standard deviation of the loss rates for items in VEG_LOSS_RATE_DF.
SELECT 
    AVG("loss_rate_%") AS "Average_Loss_Rate",
    STDDEV("loss_rate_%") AS "Loss_Rate_Std_Dev"
FROM BANK_SALES_TRADING.BANK_SALES_TRADING."VEG_LOSS_RATE_DF";