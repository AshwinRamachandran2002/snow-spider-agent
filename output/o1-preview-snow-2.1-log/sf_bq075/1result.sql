WITH google_data AS (
    SELECT
        CASE LOWER("gender_us")
            WHEN 'men' THEN 'Men'
            WHEN 'women' THEN 'Women'
            ELSE "gender_us"
        END AS "Gender",
        'Asian' AS "Race",
        "race_asian" AS "Percentage"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
    WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    UNION ALL
    SELECT
        CASE LOWER("gender_us")
            WHEN 'men' THEN 'Men'
            WHEN 'women' THEN 'Women'
            ELSE "gender_us"
        END,
        'Black' AS "Race",
        "race_black" AS "Percentage"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
    WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    UNION ALL
    SELECT
        CASE LOWER("gender_us")
            WHEN 'men' THEN 'Men'
            WHEN 'women' THEN 'Women'
            ELSE "gender_us"
        END,
        'Hispanic/Latinx' AS "Race",
        "race_hispanic_latinx" AS "Percentage"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
    WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    UNION ALL
    SELECT
        CASE LOWER("gender_us")
            WHEN 'men' THEN 'Men'
            WHEN 'women' THEN 'Women'
            ELSE "gender_us"
        END,
        'Native American' AS "Race",
        "race_native_american" AS "Percentage"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
    WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
    UNION ALL
    SELECT
        CASE LOWER("gender_us")
            WHEN 'men' THEN 'Men'
            WHEN 'women' THEN 'Women'
            ELSE "gender_us"
        END,
        'White' AS "Race",
        "race_white" AS "Percentage"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_INTERSECTIONAL_REPRESENTATION"
    WHERE "report_year" = 2021 AND LOWER("workforce") = 'overall'
),
bls_data AS (
    SELECT
        CASE
            WHEN "industry" = 'Internet publishing and broadcasting and web search portals' THEN 'Internet Content Broadcasting'
            ELSE "industry"
        END AS "industry",
        "percent_women",
        (1 - "percent_women") AS "percent_men",
        "percent_white",
        "percent_black_or_african_american",
        "percent_asian",
        "percent_hispanic_or_latino"
    FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
    WHERE
        "year" = 2021 AND "industry" IN (
            'Internet publishing and broadcasting and web search portals',
            'Computer systems design and related services'
        )
),
gender_data AS (
    SELECT
        "industry",
        'Women' AS "Gender",
        "percent_women" AS "Gender_Percentage"
    FROM bls_data
    WHERE "percent_women" IS NOT NULL
    UNION ALL
    SELECT
        "industry",
        'Men' AS "Gender",
        "percent_men" AS "Gender_Percentage"
    FROM bls_data
    WHERE "percent_men" IS NOT NULL
),
race_data AS (
    SELECT
        "industry",
        'White' AS "Race",
        "percent_white" AS "Race_Percentage"
    FROM bls_data
    WHERE "percent_white" IS NOT NULL
    UNION ALL
    SELECT
        "industry",
        'Black or African American' AS "Race",
        "percent_black_or_african_american" AS "Race_Percentage"
    FROM bls_data
    WHERE "percent_black_or_african_american" IS NOT NULL
    UNION ALL
    SELECT
        "industry",
        'Asian' AS "Race",
        "percent_asian" AS "Race_Percentage"
    FROM bls_data
    WHERE "percent_asian" IS NOT NULL
    UNION ALL
    SELECT
        "industry",
        'Hispanic or Latino' AS "Race",
        "percent_hispanic_or_latino" AS "Race_Percentage"
    FROM bls_data
    WHERE "percent_hispanic_or_latino" IS NOT NULL
)
SELECT
    'Google' AS "Data_Source",
    'Overall Workforce' AS "Industry",
    g."Gender",
    g."Race",
    ROUND(g."Percentage", 4) AS "Percentage"
FROM google_data g
WHERE g."Percentage" IS NOT NULL

UNION ALL

SELECT
    'BLS' AS "Data_Source",
    rd."industry" AS "Industry",
    gd."Gender",
    rd."Race",
    ROUND(gd."Gender_Percentage" * rd."Race_Percentage", 4) AS "Percentage"
FROM gender_data gd
JOIN race_data rd ON gd."industry" = rd."industry"
WHERE
    gd."Gender_Percentage" IS NOT NULL
    AND rd."Race_Percentage" IS NOT NULL
    AND gd."Gender_Percentage" >= 0
    AND gd."Gender_Percentage" <= 1
    AND rd."Race_Percentage" >= 0
    AND rd."Race_Percentage" <= 1;