WITH high_income_birth_rates AS (
    SELECT 
        cs."country_code",
        cs."short_name" AS "Country",
        cs."region" AS "Region",
        AVG(id."value") AS "Average_Crude_Birth_Rate"
    FROM 
        WORLD_BANK.WORLD_BANK_WDI."INDICATORS_DATA" AS id
        JOIN WORLD_BANK.WORLD_BANK_WDI."COUNTRY_SUMMARY" AS cs
            ON id."country_code" = cs."country_code"
    WHERE 
        cs."income_group" = 'High income'
        AND id."indicator_code" = 'SP.DYN.CBRT.IN'
        AND id."year" BETWEEN 1980 AND 1989
        AND cs."region" <> ''
    GROUP BY 
        cs."country_code",
        cs."short_name",
        cs."region"
),
max_birth_rates AS (
    SELECT
        "Region",
        MAX("Average_Crude_Birth_Rate") AS "Max_Average_Crude_Birth_Rate"
    FROM 
        high_income_birth_rates
    GROUP BY
        "Region"
)
SELECT
    h."Country",
    h."Region",
    ROUND(h."Average_Crude_Birth_Rate", 4) AS "Average Crude Birth Rate"
FROM
    high_income_birth_rates h
    JOIN max_birth_rates m
        ON h."Region" = m."Region"
        AND h."Average_Crude_Birth_Rate" = m."Max_Average_Crude_Birth_Rate"
ORDER BY
    h."Region";