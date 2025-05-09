WITH
WorkforceHiring AS (
    SELECT
        CASE "Category"
            WHEN 'race_asian' THEN 'Asian'
            WHEN 'race_black' THEN 'Black'
            WHEN 'race_hispanic_latinx' THEN 'Hispanic/Latinx'
            WHEN 'race_white' THEN 'White'
            WHEN 'gender_us_women' THEN 'U.S. Women'
            WHEN 'gender_us_men' THEN 'U.S. Men'
        END AS "Category",
        Workforce_Hiring_Percentage
    FROM (
        SELECT * FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
        WHERE "report_year" = 2021 AND "workforce" = 'overall'
    )
    UNPIVOT (
        Workforce_Hiring_Percentage FOR "Category" IN (
            "race_asian",
            "race_black",
            "race_hispanic_latinx",
            "race_white",
            "gender_us_women",
            "gender_us_men"
        )
    )
),
WorkforceRepresentation AS (
    SELECT
        CASE "Category"
            WHEN 'race_asian' THEN 'Asian'
            WHEN 'race_black' THEN 'Black'
            WHEN 'race_hispanic_latinx' THEN 'Hispanic/Latinx'
            WHEN 'race_white' THEN 'White'
            WHEN 'gender_us_women' THEN 'U.S. Women'
            WHEN 'gender_us_men' THEN 'U.S. Men'
        END AS "Category",
        Workforce_Representation_Percentage
    FROM (
        SELECT * FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
        WHERE "report_year" = 2021 AND "workforce" = 'overall'
    )
    UNPIVOT (
        Workforce_Representation_Percentage FOR "Category" IN (
            "race_asian",
            "race_black",
            "race_hispanic_latinx",
            "race_white",
            "gender_us_women",
            "gender_us_men"
        )
    )
),
BLSSector AS (
    SELECT
        CASE "Category"
            WHEN 'percent_asian' THEN 'Asian'
            WHEN 'percent_black_or_african_american' THEN 'Black'
            WHEN 'percent_hispanic_or_latino' THEN 'Hispanic/Latinx'
            WHEN 'percent_white' THEN 'White'
            WHEN 'percent_women' THEN 'U.S. Women'
            WHEN 'percent_men' THEN 'U.S. Men'
        END AS "Category",
        AVG(BLS_Sector_Percentage) AS BLS_Sector_Percentage
    FROM (
        SELECT
            "industry",
            "percent_asian",
            "percent_black_or_african_american",
            "percent_hispanic_or_latino",
            "percent_white",
            "percent_women",
            (100 - "percent_women") AS "percent_men"
        FROM
            "GOOGLE_DEI"."BLS"."CPSAAT18"
        WHERE
            "year" = 2021 AND (
                "industry_group" = 'Computer systems design and related services' OR
                "industry_group" = 'Software publishers'
            )
            AND "percent_asian" IS NOT NULL
    ) t
    UNPIVOT (
        BLS_Sector_Percentage FOR "Category" IN (
            "percent_asian",
            "percent_black_or_african_american",
            "percent_hispanic_or_latino",
            "percent_white",
            "percent_women",
            "percent_men"
        )
    )
    GROUP BY "Category"
)
SELECT
    COALESCE(wf."Category", wr."Category", bs."Category") AS "Category",
    ROUND(wf.Workforce_Hiring_Percentage, 4) AS Workforce_Hiring_Percentage,
    ROUND(wr.Workforce_Representation_Percentage, 4) AS Workforce_Representation_Percentage,
    ROUND(bs.BLS_Sector_Percentage, 4) AS BLS_Sector_Percentage
FROM
    WorkforceHiring wf
    FULL OUTER JOIN WorkforceRepresentation wr ON wf."Category" = wr."Category"
    FULL OUTER JOIN BLSSector bs ON COALESCE(wf."Category", wr."Category") = bs."Category"
ORDER BY
    "Category";