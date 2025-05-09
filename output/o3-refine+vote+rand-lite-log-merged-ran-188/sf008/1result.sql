/* ------------------------------------------------------------
   % CHANGE: 2023-01-01  →  2023-12-31
   Metro Area : Phoenix-Mesa-Scottsdale, AZ  (GEO_ID = geoId/C38060)
-------------------------------------------------------------*/

WITH 

/* 1)  Counties that make up the Phoenix-Mesa-Scottsdale CBSA */
counties AS (
    SELECT  "RELATED_GEO_ID"      AS "COUNTY_GEO_ID"
    FROM    US_REAL_ESTATE.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE   "GEO_ID"           = 'geoId/C38060'          -- CBSA
      AND   "RELATED_LEVEL"    = 'County'
      AND   "RELATIONSHIP_TYPE"= 'Contains'
),

/* 2)  Annual gross-income inflow for those counties, 2023  */
gross AS (
    SELECT
        "DATE",
        SUM("VALUE")            AS "TOTAL_VALUE"
    FROM   US_REAL_ESTATE.CYBERSYN.IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES
    WHERE  "VARIABLE" = 'Inflow_Returns_–_adjusted_gross_income_from_Year_1,_all_ages,_All_AGI_classes'
      AND  "GEO_ID"   IN (SELECT "COUNTY_GEO_ID" FROM counties)
      AND  "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP  BY "DATE"
),

gross_rank AS (
    SELECT
        "TOTAL_VALUE",
        "DATE",
        ROW_NUMBER() OVER (ORDER BY "DATE")        AS rn_asc,
        ROW_NUMBER() OVER (ORDER BY "DATE" DESC)   AS rn_desc
    FROM   gross
),

gross_stats AS (
    SELECT
        MAX(CASE WHEN rn_asc  = 1 THEN "TOTAL_VALUE" END) AS "START_VAL",
        MAX(CASE WHEN rn_desc = 1 THEN "TOTAL_VALUE" END) AS "END_VAL"
    FROM   gross_rank
),

/* 3)  Seasonally-adjusted purchase-only HPI for the CBSA, 2023 */
hpi AS (
    SELECT
        "DATE",
        "VALUE"
    FROM   US_REAL_ESTATE.CYBERSYN.FHFA_HOUSE_PRICE_TIMESERIES
    WHERE  "VARIABLE" = 'FHFA_HPI_traditional_purchase-only_quarterly_SA'
      AND  "GEO_ID"   = 'geoId/C38060'
      AND  "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
),

hpi_rank AS (
    SELECT
        "VALUE",
        "DATE",
        ROW_NUMBER() OVER (ORDER BY "DATE")        AS rn_asc,
        ROW_NUMBER() OVER (ORDER BY "DATE" DESC)   AS rn_desc
    FROM   hpi
),

hpi_stats AS (
    SELECT
        MAX(CASE WHEN rn_asc  = 1 THEN "VALUE" END) AS "START_VAL",
        MAX(CASE WHEN rn_desc = 1 THEN "VALUE" END) AS "END_VAL"
    FROM   hpi_rank
)

/* 4)  Final percentage-change results */
SELECT  'Gross Income Inflow (USD)'                           AS "METRIC",
        g."START_VAL"                                         AS "START_VALUE",
        g."END_VAL"                                           AS "END_VALUE",
        (g."END_VAL" - g."START_VAL") / g."START_VAL" * 100   AS "PCT_CHANGE"
FROM    gross_stats g

UNION ALL

SELECT  'HPI (Index)',
        h."START_VAL",
        h."END_VAL",
        (h."END_VAL" - h."START_VAL") / h."START_VAL" * 100
FROM    hpi_stats h;