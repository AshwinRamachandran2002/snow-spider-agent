WITH poverty_stats AS (
    /* 5-year ACS poverty rates for the year PRIOR to the natality year */
    SELECT 2016 AS year,
           SUM(TO_NUMBER("poverty")) /
           NULLIF(SUM(TO_NUMBER("pop_determined_poverty_status")),0)  AS poverty_rate
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR

    UNION ALL
    SELECT 2017 AS year,
           SUM(TO_NUMBER("poverty")) /
           NULLIF(SUM(TO_NUMBER("pop_determined_poverty_status")),0)
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2016_5YR

    UNION ALL
    SELECT 2018 AS year,
           SUM(TO_NUMBER("poverty")) /
           NULLIF(SUM(TO_NUMBER("pop_determined_poverty_status")),0)
    FROM SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR
),

birth_stats AS (
    /* National counts of births and births WITHOUT maternal morbidity */
    SELECT EXTRACT(year FROM "Year") AS year,
           SUM(CASE WHEN "Maternal_Morbidity_YN" = 0 THEN "Births" ELSE 0 END) AS births_no_morbidity,
           SUM("Births")                                                AS births_total
    FROM   SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY_BY_MATERNAL_MORBIDITY
    WHERE  EXTRACT(year FROM "Year") BETWEEN 2016 AND 2018
    GROUP  BY EXTRACT(year FROM "Year")
),

combined AS (
    /* Merge poverty rates with morbidity-free birth percentages */
    SELECT  b.year,
            p.poverty_rate,
            b.births_no_morbidity / NULLIF(b.births_total,0)  AS no_morbidity_pct
    FROM    birth_stats   b
    JOIN    poverty_stats p
           ON p.year = b.year
)

SELECT
       CORR(poverty_rate, no_morbidity_pct) AS pearson_correlation
FROM   combined;