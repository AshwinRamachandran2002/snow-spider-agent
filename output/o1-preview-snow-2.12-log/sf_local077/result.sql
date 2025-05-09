WITH Monthly_Compositions AS (
  SELECT
    im."_year",
    im."_month",
    im."interest_id",
    AVG(im."composition") AS "avg_composition"
  FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_METRICS" im
  WHERE
    (im."_year" = 2018 AND im."_month" >= 9)
    OR (im."_year" = 2019 AND im."_month" <= 8)
  GROUP BY
    im."_year",
    im."_month",
    im."interest_id"
),
Max_Compositions_Per_Month AS (
  SELECT
    mc.*,
    ROW_NUMBER() OVER (
      PARTITION BY mc."_year", mc."_month"
      ORDER BY mc."avg_composition" DESC
    ) AS "rank"
  FROM
    Monthly_Compositions mc
),
Top_Interests_Per_Month AS (
  SELECT
    mpm."_year",
    mpm."_month",
    mpm."interest_id",
    mpm."avg_composition"
  FROM
    Max_Compositions_Per_Month mpm
  WHERE
    mpm."rank" = 1
),
Top_Interests_With_Names AS (
  SELECT
    tipm."_year",
    tipm."_month",
    tipm."interest_id",
    imap."interest_name",
    tipm."avg_composition"
  FROM
    Top_Interests_Per_Month tipm
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_MAP" imap
      ON tipm."interest_id" = imap."id"
),
Rolling_Averages AS (
  SELECT
    tipn.*,
    AVG(tipn."avg_composition") OVER (
      ORDER BY tipn."_year", tipn."_month"
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS "Rolling_Average"
  FROM
    Top_Interests_With_Names tipn
),
Final_Output AS (
  SELECT
    ra.*,
    LAG(ra."interest_name", 1) OVER (
      ORDER BY ra."_year", ra."_month"
    ) AS "Top_Ranking_Interest_Minus1Month",
    LAG(ra."interest_name", 2) OVER (
      ORDER BY ra."_year", ra."_month"
    ) AS "Top_Ranking_Interest_Minus2Months"
  FROM
    Rolling_Averages ra
)
SELECT
  DATE_FROM_PARTS(fo."_year", fo."_month", 1) AS "Date",
  fo."interest_name" AS "Interest_Name",
  ROUND(fo."avg_composition", 4) AS "Max_Index_Composition",
  ROUND(fo."Rolling_Average", 4) AS "Rolling_Average",
  fo."Top_Ranking_Interest_Minus1Month",
  fo."Top_Ranking_Interest_Minus2Months"
FROM
  Final_Output fo
ORDER BY
  fo."_year",
  fo."_month";