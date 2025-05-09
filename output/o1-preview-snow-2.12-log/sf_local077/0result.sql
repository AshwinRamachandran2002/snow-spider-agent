WITH monthly_interest_avg AS (
  SELECT
    im."_year",
    im."_month",
    DATE_FROM_PARTS(im."_year", im."_month", 1) AS "Date",
    imap."interest_name" AS "Interest_Name",
    AVG(im."composition") AS "Avg_Composition"
  FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_METRICS" im
  JOIN
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_MAP" imap
      ON im."interest_id" = imap."id"
  WHERE
    im."_year" IS NOT NULL AND
    im."_month" IS NOT NULL AND
    (
      (im."_year" = 2018 AND im."_month" >= 9) OR
      (im."_year" = 2019 AND im."_month" <= 8)
    )
  GROUP BY
    im."_year", im."_month", imap."interest_name"
),
top_monthly_interest AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY "_year", "_month" ORDER BY "Avg_Composition" DESC) AS rn
  FROM
    monthly_interest_avg
)
SELECT
  TO_CHAR(t."Date", 'MON-YYYY') AS "Date",
  t."Interest_Name",
  ROUND(t."Avg_Composition", 4) AS "Max_Index_Composition",
  ROUND(AVG(t."Avg_Composition") OVER (
    ORDER BY t."_year", t."_month"
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 4) AS "Rolling_Average",
  LAG(t."Interest_Name", 1) OVER (ORDER BY t."_year", t."_month") AS "Top_Ranking_Interest_Minus1Month",
  LAG(t."Interest_Name", 2) OVER (ORDER BY t."_year", t."_month") AS "Top_Ranking_Interest_Minus2Months"
FROM
  top_monthly_interest t
WHERE t.rn = 1
ORDER BY
  t."_year" NULLS LAST, t."_month" NULLS LAST;