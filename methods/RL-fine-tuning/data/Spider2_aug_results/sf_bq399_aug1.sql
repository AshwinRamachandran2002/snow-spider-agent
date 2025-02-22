-- Task: List the average crude birth rate for each high-income country in each region during the 1980s. Limit the output to 100 rows.
SELECT
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
ORDER BY
    cs."region"
LIMIT 100