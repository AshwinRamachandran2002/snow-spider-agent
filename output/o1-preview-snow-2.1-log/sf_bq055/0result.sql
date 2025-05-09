WITH google_data AS (
    SELECT
        "race_asian" AS google_race_asian,
        "race_black" AS google_race_black,
        "race_hispanic_latinx" AS google_race_hispanic_latinx,
        "race_white" AS google_race_white
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
    WHERE "report_year" = 2021 AND LOWER("workforce") = 'tech'
),
bls_data AS (
    SELECT
        AVG("percent_asian") AS bls_percent_asian,
        AVG("percent_black_or_african_american") AS bls_percent_black,
        AVG("percent_hispanic_or_latino") AS bls_percent_hispanic_latinx,
        AVG("percent_white") AS bls_percent_white
    FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
    WHERE "year" = 2021 AND (
        "industry_group" = 'Computer systems design and related services' OR
        "industry_group" = 'Software publishing' OR
        "industry_group" = 'Data processing, hosting, and related services' OR
        "industry_group" = 'Internet publishing and broadcasting and web search portals'
    )
)
SELECT
    'Asian' AS Race,
    ROUND((google_race_asian - bls_percent_asian) * 100, 4) AS Percentage_Difference
FROM google_data CROSS JOIN bls_data
UNION ALL
SELECT
    'White' AS Race,
    ROUND((google_race_white - bls_percent_white) * 100, 4) AS Percentage_Difference
FROM google_data CROSS JOIN bls_data
UNION ALL
SELECT
    'Black or African American' AS Race,
    ROUND((google_race_black - bls_percent_black) * 100, 4) AS Percentage_Difference
FROM google_data CROSS JOIN bls_data
ORDER BY ABS(Percentage_Difference) DESC NULLS LAST
LIMIT 3;