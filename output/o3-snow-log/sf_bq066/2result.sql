/* -----------------------------------------------------------
   Relationship between poverty and births WITHOUT maternal
   morbidity, 2016-2018
   -----------------------------------------------------------
   For every study-year (t = 2016, 2017, 2018):

   1. Poverty rate comes from the ACS 5-year ZIP Code file
      for the previous calendar year (t-1):
          t = 2016  ->  ZIP_CODES_2015_5YR
          t = 2017  ->  ZIP_CODES_2016_5YR
          t = 2018  ->  ZIP_CODES_2017_5YR
      poverty_rate = Σ poverty / Σ population-with-poverty-status

   2. Percentage of births WITHOUT maternal morbidity
      is taken from CDC WONDER Natality at the same calendar
      year (t):
          pct_no_morbidity =  Σ births (Maternal_Morbidity_YN = 0)
                              / Σ births (all records)

   3. Finally, the Pearson correlation coefficient between the
      two series (poverty_rate vs. pct_no_morbidity) is returned.
----------------------------------------------------------------*/
WITH yearly_metrics AS (

    /* ---------------- 2016 ---------------- */
    SELECT
        2016 AS year,

        /* Poverty rate from 2015 ACS 5-yr ZIP codes */
        (
            SELECT  SUM(CAST("poverty" AS FLOAT))
                    / NULLIF(SUM(CAST("pop_determined_poverty_status" AS FLOAT)),0)
            FROM    SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR
        )                                        AS poverty_rate,

        /* % births with NO maternal morbidity in 2016 */
        (
            SELECT  SUM(CASE WHEN "Maternal_Morbidity_YN" = 0
                             THEN CAST("Births" AS FLOAT) ELSE 0 END)
                    / NULLIF(SUM(CAST("Births" AS FLOAT)),0)
            FROM    SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY_BY_MATERNAL_MORBIDITY
            WHERE   "Year" = '2016-01-01'
        )                                        AS pct_no_morbidity

    UNION ALL

    /* ---------------- 2017 ---------------- */
    SELECT
        2017 AS year,

        (
            SELECT  SUM(CAST("poverty" AS FLOAT))
                    / NULLIF(SUM(CAST("pop_determined_poverty_status" AS FLOAT)),0)
            FROM    SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2016_5YR
        )                                        AS poverty_rate,

        (
            SELECT  SUM(CASE WHEN "Maternal_Morbidity_YN" = 0
                             THEN CAST("Births" AS FLOAT) ELSE 0 END)
                    / NULLIF(SUM(CAST("Births" AS FLOAT)),0)
            FROM    SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY_BY_MATERNAL_MORBIDITY
            WHERE   "Year" = '2017-01-01'
        )                                        AS pct_no_morbidity

    UNION ALL

    /* ---------------- 2018 ---------------- */
    SELECT
        2018 AS year,

        (
            SELECT  SUM(CAST("poverty" AS FLOAT))
                    / NULLIF(SUM(CAST("pop_determined_poverty_status" AS FLOAT)),0)
            FROM    SDOH.CENSUS_BUREAU_ACS.ZIP_CODES_2017_5YR
        )                                        AS poverty_rate,

        (
            SELECT  SUM(CASE WHEN "Maternal_Morbidity_YN" = 0
                             THEN CAST("Births" AS FLOAT) ELSE 0 END)
                    / NULLIF(SUM(CAST("Births" AS FLOAT)),0)
            FROM    SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY_BY_MATERNAL_MORBIDITY
            WHERE   "Year" = '2018-01-01'
        )                                        AS pct_no_morbidity
)

SELECT
    CORR(poverty_rate, pct_no_morbidity) AS pearson_corr_2016_2018
FROM
    yearly_metrics;