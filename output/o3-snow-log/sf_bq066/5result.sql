WITH poverty_rates AS (   -- poverty rate from the previous-year 5-yr ACS file
    SELECT 2016 AS "YEAR",
           SUM("poverty") /
           NULLIF( SUM( COALESCE("pop_determined_poverty_status", "total_pop") ), 0 )  AS "poverty_rate"
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR
    
    UNION ALL
    SELECT 2017 AS "YEAR",
           SUM("poverty") /
           NULLIF( SUM( COALESCE("pop_determined_poverty_status", "total_pop") ), 0 )  AS "poverty_rate"
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2016_5YR
    
    UNION ALL
    SELECT 2018 AS "YEAR",
           SUM("poverty") /
           NULLIF( SUM( COALESCE("pop_determined_poverty_status", "total_pop") ), 0 )  AS "poverty_rate"
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR
),

births AS (                -- % births with NO maternal morbidity
    SELECT  EXTRACT(year FROM "Year")::INT            AS "YEAR",
            SUM( CASE WHEN "Maternal_Morbidity_YN" = 0 THEN "Births" ELSE 0 END )  AS "births_no_morbidity",
            SUM( "Births" )                                                   AS "births_total"
    FROM    SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY_BY_MATERNAL_MORBIDITY
    WHERE   EXTRACT(year FROM "Year") BETWEEN 2016 AND 2018
    GROUP BY EXTRACT(year FROM "Year")
),

combined AS (              -- merge the two measures
    SELECT  b."YEAR",
            p."poverty_rate",
            b."births_no_morbidity" / NULLIF(b."births_total",0)    AS "pct_births_no_morbidity"
    FROM    births b
    JOIN    poverty_rates p
           ON p."YEAR" = b."YEAR"
)

-- Pearson correlation across the three yearly points (2016-2018)
SELECT  CORR( "poverty_rate", "pct_births_no_morbidity" )  AS "pearson_corr_2016_2018"
FROM    combined;