WITH yr14 AS (
    SELECT
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_native_american",
        "race_white",
        "gender_us_women",
        "gender_us_men",
        "gender_global_women",
        "gender_global_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" = 2014
),
yr24 AS (
    SELECT
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_native_american",
        "race_white",
        "gender_us_women",
        "gender_us_men",
        "gender_global_women",
        "gender_global_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" = 2024
)
SELECT
    ROUND( (yr24."race_asian"         - yr14."race_asian")         / yr14."race_asian"         * 100 , 4) AS "asian_growth_rate_pct",
    ROUND( (yr24."race_black"         - yr14."race_black")         / yr14."race_black"         * 100 , 4) AS "black_growth_rate_pct",
    ROUND( (yr24."race_hispanic_latinx" - yr14."race_hispanic_latinx") / yr14."race_hispanic_latinx" * 100 , 4) AS "latinx_growth_rate_pct",
    ROUND( (yr24."race_native_american" - yr14."race_native_american") / yr14."race_native_american" * 100 , 4) AS "native_american_growth_rate_pct",
    ROUND( (yr24."race_white"         - yr14."race_white")         / yr14."race_white"         * 100 , 4) AS "white_growth_rate_pct",
    ROUND( (yr24."gender_us_women"    - yr14."gender_us_women")    / yr14."gender_us_women"    * 100 , 4) AS "us_women_growth_rate_pct",
    ROUND( (yr24."gender_us_men"      - yr14."gender_us_men")      / yr14."gender_us_men"      * 100 , 4) AS "us_men_growth_rate_pct",
    ROUND( (yr24."gender_global_women" - yr14."gender_global_women") / yr14."gender_global_women" * 100 , 4) AS "global_women_growth_rate_pct",
    ROUND( (yr24."gender_global_men"   - yr14."gender_global_men")   / yr14."gender_global_men"   * 100 , 4) AS "global_men_growth_rate_pct"
FROM yr14, yr24;