WITH high_income_avg AS (
    SELECT
        cs."region"        AS region,
        d."country_name"   AS country_name,
        AVG(d."value")     AS avg_crude_birth_rate
    FROM WORLD_BANK.WORLD_BANK_WDI."INDICATORS_DATA"  d
    JOIN WORLD_BANK.WORLD_BANK_WDI."COUNTRY_SUMMARY"  cs
          ON d."country_code" = cs."country_code"
    WHERE d."indicator_code" = 'SP.DYN.CBRT.IN'      -- crude birth rate
      AND d."year" BETWEEN 1980 AND 1989             -- the 1980s
      AND cs."income_group" = 'High income'          -- high-income countries
      AND cs."region" IS NOT NULL                    -- keep standard regions
    GROUP BY
        region,
        country_name
),
ranked AS (
    SELECT
        region,
        country_name,
        avg_crude_birth_rate,
        ROW_NUMBER() OVER (
            PARTITION BY region
            ORDER BY avg_crude_birth_rate DESC NULLS LAST
        ) AS rn
    FROM high_income_avg
)
SELECT
    region,
    country_name,
    ROUND(avg_crude_birth_rate, 4) AS average_crude_birth_rate
FROM ranked
WHERE rn = 1
ORDER BY region;