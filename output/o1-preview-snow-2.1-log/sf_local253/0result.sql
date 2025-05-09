WITH national_avg AS (
    SELECT 
        AVG(
            CASE
                WHEN "Salary" LIKE '%/yr' THEN TRY_TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', ''))
                WHEN "Salary" LIKE '%/mo' THEN TRY_TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', '')) * 12
                ELSE NULL
                END
        ) AS "Average Salary in Country"
    FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."SALARYDATASET"
),
city_company_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(
            CASE
                WHEN "Salary" LIKE '%/yr' THEN TRY_TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', ''))
                WHEN "Salary" LIKE '%/mo' THEN TRY_TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', '')) * 12
                ELSE NULL
                END
        ) AS "Average Salary in State"
    FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."SALARYDATASET"
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
top_companies AS (
    SELECT 
        "Location",
        "CompanyName",
        "Average Salary in State",
        ROW_NUMBER() OVER (
            PARTITION BY "Location" 
            ORDER BY "Average Salary in State" DESC NULLS LAST
        ) AS "rn"
    FROM city_company_avg
)
SELECT
    "Location",
    "CompanyName",
    ROUND("Average Salary in State", 4) AS "Average Salary in State",
    ROUND(national_avg."Average Salary in Country", 4) AS "Average Salary in Country"
FROM top_companies, national_avg
WHERE "rn" <= 5
ORDER BY "Location", "Average Salary in State" DESC NULLS LAST;