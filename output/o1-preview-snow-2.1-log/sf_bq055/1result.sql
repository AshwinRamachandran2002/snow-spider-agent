WITH bls_data AS (
    SELECT
        AVG(b."percent_asian") AS "bls_percent_asian",
        AVG(b."percent_black_or_african_american") AS "bls_percent_black",
        AVG(b."percent_hispanic_or_latino") AS "bls_percent_hispanic_latinx",
        AVG(b."percent_white") AS "bls_percent_white"
    FROM "GOOGLE_DEI"."BLS"."CPSAAT18" AS b
    WHERE b."year" = 2021 AND (
        b."industry" ILIKE '%Internet content broadcast%' OR
        b."industry" ILIKE '%Software publishing%' OR
        b."industry" ILIKE '%Data management%' OR
        b."industry" ILIKE '%Hosting%' OR
        b."industry_group" ILIKE '%Computer systems design and related services%'
    )
),
google_data AS (
    SELECT
        g."race_asian" AS "google_race_asian",
        g."race_black" AS "google_race_black",
        g."race_hispanic_latinx" AS "google_race_hispanic_latinx",
        g."race_white" AS "google_race_white"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING" AS g
    WHERE g."report_year" = 2021 AND LOWER(g."workforce") = 'tech'
),
differences AS (
    SELECT
        'Asian' AS "Race",
        ROUND((g."google_race_asian" - b."bls_percent_asian") * 100, 4) AS "Percentage_Difference"
    FROM google_data g CROSS JOIN bls_data b
    UNION ALL
    SELECT
        'White' AS "Race",
        ROUND((g."google_race_white" - b."bls_percent_white") * 100, 4) AS "Percentage_Difference"
    FROM google_data g CROSS JOIN bls_data b
    UNION ALL
    SELECT
        'Black or African American' AS "Race",
        ROUND((g."google_race_black" - b."bls_percent_black") * 100, 4) AS "Percentage_Difference"
    FROM google_data g CROSS JOIN bls_data b
    UNION ALL
    SELECT
        'Hispanic or Latinx' AS "Race",
        ROUND((g."google_race_hispanic_latinx" - b."bls_percent_hispanic_latinx") * 100, 4) AS "Percentage_Difference"
    FROM google_data g CROSS JOIN bls_data b
)
SELECT *
FROM differences
ORDER BY ABS("Percentage_Difference") DESC NULLS LAST
LIMIT 3;