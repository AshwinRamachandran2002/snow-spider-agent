WITH poverty_rates AS (  -- poverty rate from the 5-year ACS file published the year *before* the natality year
    SELECT 2016 AS birth_year,
           SUM("poverty") / NULLIF(SUM(COALESCE("pop_determined_poverty_status","total_pop")),0) AS poverty_rate_prev
    FROM   SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR
    UNION ALL
    SELECT 2017,
           SUM("poverty") / NULLIF(SUM(COALESCE("pop_determined_poverty_status","total_pop")),0)
    FROM   SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2016_5YR
    UNION ALL
    SELECT 2018,
           SUM("poverty") / NULLIF(SUM(COALESCE("pop_determined_poverty_status","total_pop")),0)
    FROM   SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR
),  

births_totals AS (      -- total births and births WITHOUT maternal morbidity for each year
    SELECT  YEAR("Year")                           AS birth_year,
            SUM("Births")                          AS total_births,
            SUM(CASE WHEN "Maternal_Morbidity_YN" = 0 THEN "Births" ELSE 0 END) 
                                                    AS births_no_morbidity
    FROM    SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY_BY_MATERNAL_MORBIDITY
    WHERE   YEAR("Year") BETWEEN 2016 AND 2018
    GROUP BY YEAR("Year")
),  

births_pct AS (         -- percentage of births with NO maternal morbidity
    SELECT  birth_year,
            births_no_morbidity,
            total_births,
            births_no_morbidity / NULLIF(total_births,0)  AS pct_births_no_morbidity
    FROM    births_totals
),  

combined AS (           -- match poverty rate (prev-year) to natality year
    SELECT  p.birth_year,
            p.poverty_rate_prev,
            b.pct_births_no_morbidity
    FROM    poverty_rates p
    JOIN    births_pct    b USING (birth_year)
)

-- final Pearson correlation across the three years (2016-2018)
SELECT  CORR(poverty_rate_prev , pct_births_no_morbidity) AS pearson_correlation
FROM    combined;