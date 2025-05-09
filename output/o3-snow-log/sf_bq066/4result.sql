WITH poverty_rates AS (
    /* Poverty rate from the 5-year ACS file published the year BEFORE the natality year */
    SELECT 2016                          AS "year",
           SUM(CAST("poverty"    AS FLOAT))
           /
           NULLIF(SUM(CAST("total_pop" AS FLOAT)),0)   AS "poverty_rate"
    FROM   SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
    
    UNION ALL
    
    SELECT 2017,
           SUM(CAST("poverty"    AS FLOAT))
           /
           NULLIF(SUM(CAST("total_pop" AS FLOAT)),0)
    FROM   SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2016_5YR"
    
    UNION ALL
    
    SELECT 2018,
           SUM(CAST("poverty"    AS FLOAT))
           /
           NULLIF(SUM(CAST("total_pop" AS FLOAT)),0)
    FROM   SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
),

births_pct AS (
    /* % of births with NO maternal morbidity for each year */
    SELECT  YEAR("Year")                                           AS "year",
            SUM(CASE WHEN "Maternal_Morbidity_YN" = 0 
                     THEN "Births" ELSE 0 END)
            /
            NULLIF(SUM("Births"),0)                               AS "pct_births_no_morbidity"
    FROM    SDOH.SDOH_CDC_WONDER_NATALITY."COUNTY_NATALITY_BY_MATERNAL_MORBIDITY"
    WHERE   YEAR("Year") IN (2016, 2017, 2018)
    GROUP BY YEAR("Year")
),

combined AS (
    /* Pair each natality year with its poverty rate from the preceding year */
    SELECT  p."year",
            p."poverty_rate",
            b."pct_births_no_morbidity"
    FROM    poverty_rates p
    JOIN    births_pct    b
      ON    p."year" = b."year"
)

/* Pearson correlation between prior–year poverty rate and
   % births without maternal morbidity (2016-2018)              */
SELECT  CORR("poverty_rate", "pct_births_no_morbidity") AS "pearson_corr_coef"
FROM    combined;