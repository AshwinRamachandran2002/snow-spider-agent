/* -----------------------------------------------------------
   % change (2023) for
   1) Gross-income inflow (total AGI) – Phoenix-Mesa-Scottsdale, AZ CBSA  
   2) Seasonally-adjusted purchase-only FHFA House-Price Index – same CBSA
   ----------------------------------------------------------- */
WITH county_list AS (   -- counties that make up the Phoenix-Mesa-Scottsdale Metro (geoId/C38060)
    SELECT DISTINCT
           "RELATED_GEO_ID"  AS county_geo_id
    FROM   US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE  "GEO_ID"          = 'geoId/C38060'
      AND  "RELATIONSHIP_TYPE" = 'Contains'
      AND  "RELATED_LEVEL"     = 'County'
),

agi_raw AS (            -- aggregate 2022 & 2023 county-level inflow AGI
    SELECT
           SUM( CASE WHEN m."DATE" = '2022-12-31' THEN m."VALUE" END ) AS agi_2022,
           SUM( CASE WHEN m."DATE" = '2023-12-31' THEN m."VALUE" END ) AS agi_2023
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES m
           JOIN county_list c
             ON m."GEO_ID" = c.county_geo_id
    WHERE  m."VARIABLE" = 'Inflow_Returns_–_adjusted_gross_income_from_Year_2,_all_ages,_All_AGI_classes'
      AND  m."DATE" IN ('2022-12-31','2023-12-31')
      AND  m."VALUE" IS NOT NULL
),

agi_pct AS (            -- % change for 2023
    SELECT
           (agi_2023 / agi_2022 - 1) * 100  AS gross_income_inflow_pct_change_2023
    FROM   agi_raw
),

hpi_raw AS (            -- Q1 vs Q4 2023 FHFA purchase-only SA index
    SELECT
           MAX( CASE WHEN "DATE" = '2023-03-31' THEN "VALUE" END ) AS hpi_q1_2023,
           MAX( CASE WHEN "DATE" = '2023-12-31' THEN "VALUE" END ) AS hpi_q4_2023
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE  "GEO_ID"   = 'geoId/C38060'   -- Phoenix-Mesa-Scottsdale CBSA
      AND  "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_quarterly_SA'
      AND  "DATE" IN ('2023-03-31','2023-12-31')
),

hpi_pct AS (            -- % change for 2023
    SELECT
           (hpi_q4_2023 / hpi_q1_2023 - 1) * 100  AS hpi_sa_purchaseonly_pct_change_2023
    FROM   hpi_raw
)

-- Final result: both percentage changes side-by-side
SELECT
       a.gross_income_inflow_pct_change_2023      AS "Gross_Income_Inflow_%_Change_2023",
       h.hpi_sa_purchaseonly_pct_change_2023      AS "FHFA_PurchaseOnly_SA_HPI_%_Change_2023"
FROM   agi_pct a
       CROSS JOIN hpi_pct h;