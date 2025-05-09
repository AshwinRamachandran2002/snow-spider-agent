WITH avg_compositions AS (
  SELECT
    m."_year",
    m."_month",
    CONCAT(LPAD(CAST(m."_month" AS VARCHAR), 2, '0'), '-', CAST(m."_year" AS VARCHAR)) AS "Date",
    im."interest_name",
    AVG(m."composition") AS "Max_Index_Composition"
  FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_METRICS" m
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_MAP" im
      ON m."interest_id" = im."id"
  WHERE
    (m."_year" = 2018 AND m."_month" >= 9) OR (m."_year" = 2019 AND m."_month" <= 8)
  GROUP BY
    m."_year",
    m."_month",
    im."interest_name"
),
ranked_max AS (
  SELECT
    ac."Date",
    ac."_year",
    ac."_month",
    ac."interest_name",
    ac."Max_Index_Composition",
    ROW_NUMBER() OVER (PARTITION BY ac."_year", ac."_month" ORDER BY ac."Max_Index_Composition" DESC) AS "rank"
  FROM
    avg_compositions ac
),
top_interests AS (
  SELECT
    rm."Date",
    rm."interest_name",
    rm."Max_Index_Composition",
    AVG(rm."Max_Index_Composition") OVER (ORDER BY rm."_year", rm."_month" ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS "Rolling_Average",
    LAG(rm."interest_name", 1) OVER (ORDER BY rm."_year", rm."_month") AS "Top_Ranking_Interest_Minus1Month",
    LAG(rm."interest_name", 2) OVER (ORDER BY rm."_year", rm."_month") AS "Top_Ranking_Interest_Minus2Months"
  FROM
    ranked_max rm
  WHERE
    rm."rank" = 1
  ORDER BY
    rm."_year",
    rm."_month"
)
SELECT
  "Date",
  "interest_name" AS "Interest_Name",
  ROUND("Max_Index_Composition", 4) AS "Max_Index_Composition",
  ROUND("Rolling_Average", 4) AS "Rolling_Average",
  "Top_Ranking_Interest_Minus1Month",
  "Top_Ranking_Interest_Minus2Months"
FROM
  top_interests;