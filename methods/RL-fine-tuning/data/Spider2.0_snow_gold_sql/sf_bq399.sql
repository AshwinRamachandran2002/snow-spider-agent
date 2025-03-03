WITH avg_birth_rates AS (
    SELECT
        cs."country_code",
        cs."short_name" AS "Country",
        cs."region" AS "Region",
        ROUND(AVG(id."value"), 4) AS "Average Crude Birth Rate"
    FROM
        WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY cs
    JOIN
        WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA id
        ON cs."country_code" = id."country_code"
    WHERE
        cs."income_group" = 'High income'
        AND id."indicator_code" = 'SP.DYN.CBRT.IN'
        AND id."year" BETWEEN 1980 AND 1989
        AND cs."region" IS NOT NULL
        AND cs."region" <> ''
    GROUP BY
        cs."country_code", cs."short_name", cs."region"
),
max_birth_rates AS (
    SELECT
        "Region",
        MAX("Average Crude Birth Rate") AS "Max_Average_Crude_Birth_Rate"
    FROM
        avg_birth_rates
    GROUP BY
        "Region"
)

SELECT
    abr."Country",
    abr."Region",
    abr."Average Crude Birth Rate"
FROM
    avg_birth_rates abr
JOIN
   max_birth_rates mbr
   ON abr."Region" = mbr."Region"
   AND abr."Average Crude Birth Rate" = mbr."Max_Average_Crude_Birth_Rate"
ORDER BY
    abr."Region"