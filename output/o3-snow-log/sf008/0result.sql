/*---------------------------------------------------------------------------
  % CHANGE (2023 vs. 2022) IN
  1)  GROSS INCOME INFLOW (AGI) INTO THE PHOENIX-MESA-SCOTTSDALE MSA
      –  sum of county-level inflows for Maricopa (04013) & Pinal (04021)
  2)  SEASONALLY-ADJUSTED, PURCHASE-ONLY FHFA HOUSE-PRICE INDEX
      –  CBSA code geoId/C38060

  Output: one row per metric with its 12-month % change.
---------------------------------------------------------------------------*/
WITH county_list AS (      -- counties that make up the Phoenix-Mesa-Scottsdale, AZ metro
    SELECT 'geoId/04013' AS "GEO_ID"   -- Maricopa County
    UNION ALL
    SELECT 'geoId/04021'               -- Pinal County
),

/* -------- 1)  AGGREGATE 2022 & 2023 AGI INFLOWS ------------------------- */
agi_ts AS (
    SELECT
        t."DATE",
        SUM(t."VALUE") AS "VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES t
    JOIN county_list c
          ON t."GEO_ID" = c."GEO_ID"
    -- unique variable: “Inflow … adjusted gross income … all ages … All AGI classes”
    WHERE t."VARIABLE" ILIKE 'Inflow%adjusted%gross%income%all_ages%All_AGI_classes%'
      AND t."DATE"      IN ('2022-12-31','2023-12-31')
    GROUP BY t."DATE"
),
agi_pct AS (
    SELECT
        ( MAX(CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END)
        - MAX(CASE WHEN "DATE" = '2022-12-31' THEN "VALUE" END)
        )
        / NULLIF( MAX(CASE WHEN "DATE" = '2022-12-31' THEN "VALUE" END) ,0 ) * 100
        AS "PERCENT_CHANGE"
    FROM agi_ts
),

/* -------- 2)  HPI: FIRST & LAST QUARTERS OF 2023 ------------------------ */
hpi_ts AS (
    SELECT
        "DATE",
        "VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE "GEO_ID"  = 'geoId/C38060'  -- Phoenix-Mesa-Scottsdale, AZ CBSA
      AND "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_quarterly_SA'
      AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
),
hpi_pct AS (
    SELECT
        ( MAX(CASE WHEN "DATE" = (SELECT MAX("DATE") FROM hpi_ts) THEN "VALUE" END)
        - MAX(CASE WHEN "DATE" = (SELECT MIN("DATE") FROM hpi_ts) THEN "VALUE" END)
        )
        / NULLIF( MAX(CASE WHEN "DATE" = (SELECT MIN("DATE") FROM hpi_ts) THEN "VALUE" END) ,0 ) * 100
        AS "PERCENT_CHANGE"
    FROM hpi_ts
)

/* ------------------- FINAL RESULT -------------------------------------- */
SELECT 'Gross Income Inflow (AGI)'  AS "METRIC",
       ROUND(p."PERCENT_CHANGE",4)  AS "PERCENT_CHANGE_PCT"
FROM   agi_pct p

UNION ALL

SELECT 'Purchase-Only HPI (SA)'     AS "METRIC",
       ROUND(p."PERCENT_CHANGE",4)  AS "PERCENT_CHANGE_PCT"
FROM   hpi_pct p;