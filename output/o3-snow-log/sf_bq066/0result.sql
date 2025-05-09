/*-------------------------------------------------------------------
   1.  Build the poverty-rate for each target year (2016-2018) from
       the previous year’s 5-year ACS ZIP Code files
-------------------------------------------------------------------*/
WITH poverty_prev_year AS (
    /* 2015 ACS 5-YR  →  2016 outcome year */
    SELECT
        2016                                                    AS "year",
        SUM("poverty") / SUM("pop_determined_poverty_status")   AS "poverty_rate"
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR
    
    UNION ALL
    
    /* 2016 ACS 5-YR  →  2017 outcome year */
    SELECT
        2017,
        SUM("poverty") / SUM("pop_determined_poverty_status")
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2016_5YR
    
    UNION ALL
    
    /* 2017 ACS 5-YR  →  2018 outcome year */
    SELECT
        2018,
        SUM("poverty") / SUM("pop_determined_poverty_status")
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR
),

/*-------------------------------------------------------------------
   2.  Calculate, for each year 2016-2018, the proportion of births
       in which NO maternal morbidity was reported
-------------------------------------------------------------------*/
births_no_morb AS (
    SELECT
        EXTRACT(YEAR FROM "Year")                                            AS "year",
        SUM(CASE WHEN "Maternal_Morbidity_YN" = 0 THEN "Births" ELSE 0 END) AS "births_without_morbidity",
        SUM("Births")                                                        AS "all_births"
    FROM SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY_BY_MATERNAL_MORBIDITY
    WHERE EXTRACT(YEAR FROM "Year") BETWEEN 2016 AND 2018
    GROUP BY EXTRACT(YEAR FROM "Year")
),

/*-------------------------------------------------------------------
   3.  Combine poverty rates with the “no-maternal-morbidity”
       birth percentages for each year
-------------------------------------------------------------------*/
combined AS (
    SELECT
        p."year",
        p."poverty_rate",
        b."births_without_morbidity" / b."all_births"             AS "pct_births_no_morbidity"
    FROM poverty_prev_year p
    JOIN births_no_morb        b
      ON p."year" = b."year"
)

/*-------------------------------------------------------------------
   4.  Assess the relationship across the three observation years by
       computing the Pearson correlation coefficient
-------------------------------------------------------------------*/
SELECT
    CORR("poverty_rate", "pct_births_no_morbidity")  AS "pearson_corr_2016_2018"
FROM combined;