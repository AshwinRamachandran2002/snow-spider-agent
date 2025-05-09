/* ---------------------------------------------------------------
   Correlation between prior-year poverty counts (ACS 5-year files)
   and the share of births WITHOUT maternal morbidity, 2016-2018
   ----------------------------------------------------------------*/
WITH poverty_by_year AS (
    /* Poverty totals from the 5-year ACS file that ended the year
       BEFORE the birth year                                           */
    SELECT 2016           AS "year",
           SUM(CAST("poverty" AS FLOAT)) AS "poverty_prev_year"
    FROM   SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
    
    UNION ALL
    SELECT 2017,
           SUM("poverty")               AS "poverty_prev_year"
    FROM   SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2016_5YR"
    
    UNION ALL
    SELECT 2018,
           SUM("poverty")               AS "poverty_prev_year"
    FROM   SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
),

births_by_year AS (
    /* Split births into those WITH and WITHOUT maternal morbidity     */
    SELECT  EXTRACT(year FROM "Year")                                  AS "year",
            SUM(CASE WHEN "Maternal_Morbidity_YN" = 0  THEN "Births" END) AS "births_no_mm",
            SUM("Births")                                              AS "total_births"
    FROM    SDOH.SDOH_CDC_WONDER_NATALITY."COUNTY_NATALITY_BY_MATERNAL_MORBIDITY"
    WHERE   EXTRACT(year FROM "Year") BETWEEN 2016 AND 2018
    GROUP BY 1
),

combined AS (
    SELECT  p."year",
            p."poverty_prev_year",
            /* percentage of births with NO maternal morbidity         */
            b."births_no_mm" / NULLIF(b."total_births",0)              AS "pct_births_no_mm"
    FROM    poverty_by_year p
    JOIN    births_by_year  b USING ("year")
)

SELECT  CORR("poverty_prev_year", "pct_births_no_mm") AS "pearson_corr_2016_2018",
        COUNT(*)                                       AS "number_of_years"
FROM    combined;