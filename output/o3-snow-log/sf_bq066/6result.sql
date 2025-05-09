/* --------------------------------------------------------------
   Relationship between poverty rates (from prior-year ACS 5-year
   ZIP-Code files) and the % of births WITHOUT maternal morbidity
   for birth-years 2016-2018.
   -------------------------------------------------------------- */
WITH poverty_totals AS (
    /* ---------- 5-year ACS ZIP-Code data (prior year) ---------- */
    SELECT 2015 AS census_year,
           SUM("poverty"::FLOAT)                         AS tot_poverty,
           SUM("pop_determined_poverty_status"::FLOAT)   AS tot_pop_determined
      FROM SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"

    UNION ALL
    SELECT 2016,
           SUM("poverty"::FLOAT),
           SUM("pop_determined_poverty_status"::FLOAT)
      FROM SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2016_5YR"

    UNION ALL
    SELECT 2017,
           SUM("poverty"::FLOAT),
           SUM("pop_determined_poverty_status"::FLOAT)
      FROM SDOH.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
),
poverty_rates AS (
    /* Poverty rate for each ACS file */
    SELECT
        census_year,
        tot_poverty / NULLIF(tot_pop_determined,0)      AS poverty_rate
    FROM poverty_totals
),
births AS (
    /* ---------- Natality data (county-level, all counties) ---------- */
    SELECT
        YEAR("Year")                                    AS birth_year,
        SUM("Births")                                   AS total_births,
        SUM(CASE WHEN "Maternal_Morbidity_YN" = 1
                 THEN "Births" ELSE 0 END)              AS births_with_morbidity
    FROM SDOH.SDOH_CDC_WONDER_NATALITY."COUNTY_NATALITY_BY_MATERNAL_MORBIDITY"
    WHERE YEAR("Year") BETWEEN 2016 AND 2018
    GROUP BY YEAR("Year")
),
births_pct_without AS (
    /* % of births WITHOUT maternal morbidity */
    SELECT
        birth_year,
        100.0 * (total_births - births_with_morbidity) / NULLIF(total_births,0)
            AS pct_births_without_morbidity
    FROM births
),
joined AS (
    /* Match each birth year with the poverty rate from the previous ACS year */
    SELECT
        b.birth_year,
        p.poverty_rate,
        b.pct_births_without_morbidity
    FROM births_pct_without   b
    JOIN poverty_rates        p
      ON p.census_year = b.birth_year - 1
)
SELECT
    CORR(poverty_rate, pct_births_without_morbidity)    AS pearson_correlation
FROM joined;