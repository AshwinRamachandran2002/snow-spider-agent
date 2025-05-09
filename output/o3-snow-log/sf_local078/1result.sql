/*--------------------------------------------------------------------
  1. For every interest_id, identify the month in which it recorded its
     highest composition value (if ties, keep the earliest month_year).
  2. Join to INTEREST_MAP to get the interest_name.
  3. Rank the interests by that maximum composition (both descending
     and ascending) and pick the top-10 and bottom-10.
--------------------------------------------------------------------*/
WITH interest_best_month AS (   -- step-1
    SELECT
        imt."interest_id",
        imt."month_year",
        imt."composition",
        MAX(imt."composition") OVER (PARTITION BY imt."interest_id")   AS max_comp
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS" imt
),
best_per_interest AS (          -- keep only the row(s) where composition is the max
    SELECT
        ibm."interest_id",
        ibm."month_year",
        ibm."composition"
    FROM interest_best_month ibm
    QUALIFY  ibm."composition" = ibm.max_comp
         AND ROW_NUMBER() OVER (PARTITION BY ibm."interest_id"
                                ORDER BY ibm."month_year") = 1   -- earliest if tie
),
interest_with_name AS (         -- step-2
    SELECT
        bpi."month_year",
        im."interest_name",
        bpi."composition"
    FROM best_per_interest  bpi
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP" im
          ON bpi."interest_id" = im."id"
),
ranked AS (                      -- step-3
    SELECT
        iwn."month_year",
        iwn."interest_name",
        iwn."composition",
        DENSE_RANK() OVER (ORDER BY iwn."composition" DESC) AS desc_rank,
        DENSE_RANK() OVER (ORDER BY iwn."composition" ASC)  AS asc_rank
    FROM interest_with_name iwn
)
SELECT
    "month_year",
    "interest_name",
    "composition"
FROM ranked
WHERE desc_rank <= 10            -- top-10 by highest composition
   OR asc_rank  <= 10            -- bottom-10 by highest composition
ORDER BY
      CASE WHEN desc_rank <= 10 THEN 0 ELSE 1 END,  -- show top-10 first
      desc_rank, asc_rank;