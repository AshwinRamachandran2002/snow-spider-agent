SELECT MEDIAN("AverageMonthlySpending") AS "median_average_monthly_spending"
FROM (
  SELECT
    ord."O_CUSTKEY" AS "CustomerID",
    SUM(line."L_EXTENDEDPRICE") / 12 AS "AverageMonthlySpending"
  FROM
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1."ORDERS" AS ord
  JOIN
    SNOWFLAKE_SAMPLE_DATA.TPCH_SF1."LINEITEM" AS line
    ON ord."O_ORDERKEY" = line."L_ORDERKEY"
  WHERE
    YEAR(ord."O_ORDERDATE") = 1996
  GROUP BY
    ord."O_CUSTKEY"
);