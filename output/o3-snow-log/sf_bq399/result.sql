WITH high_income_80s AS ( 
    SELECT
        cs."region",
        id."country_name",
        AVG(id."value") AS avg_birth_rate
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA         id
    JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY          cs
          ON id."country_code" = cs."country_code"
    WHERE id."indicator_code" = 'SP.DYN.CBRT.IN'          -- crude birth rate
      AND id."year" BETWEEN 1980 AND 1989                 -- the 1980s
      AND cs."income_group" = 'High income'               -- high-income economies
      AND id."value" IS NOT NULL
    GROUP BY cs."region", id."country_name"
), ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "region"
                           ORDER BY avg_birth_rate DESC NULLS LAST) AS rn
    FROM high_income_80s
)
SELECT
    "region",
    "country_name",
    ROUND(avg_birth_rate, 4) AS avg_birth_rate
FROM ranked
WHERE rn = 1
ORDER BY "region";