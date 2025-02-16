-- Task: Provide the total number of Bitcoin transactions, total inputs, total outputs, total input value, and total output value for each month in 2021.
SELECT
    "txs_tot"."block_timestamp_month" AS tx_month,
    COUNT("txs_tot"."hash") AS tx_count,
    SUM("txs_tot"."input_count") AS tx_inputs,
    SUM("txs_tot"."output_count") AS tx_outputs,
    SUM("txs_tot"."input_value") / 100000000 AS tx_input_val,
    SUM("txs_tot"."output_value") / 100000000 AS tx_output_val
FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS AS "txs_tot"
WHERE "txs_tot"."block_timestamp_month" BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2021-12-31' AS DATE)
GROUP BY "txs_tot"."block_timestamp_month"
ORDER BY "txs_tot"."block_timestamp_month" DESC;