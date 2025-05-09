WITH birth_avg AS (
    SELECT
        c."region",
        h."country_name",
        h."country_code",
        AVG(h."value") AS avg_birth_rate
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION h
    JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY c
      ON h."country_code" = c."country_code"
    WHERE h."indicator_code" = 'SP.DYN.CBRT.IN'          -- crude birth rate
      AND h."year" BETWEEN 1980 AND 1989                 -- the 1980s
      AND c."income_group" ILIKE 'High income%'          -- high-income economies
      AND h."value" IS NOT NULL
      AND c."region" IS NOT NULL
    GROUP BY
        c."region",
        h."country_name",
        h."country_code"
),
ranked AS (
    SELECT
        "region",
        "country_name",
        avg_birth_rate,
        ROW_NUMBER() OVER (PARTITION BY "region"
                           ORDER BY avg_birth_rate DESC NULLS LAST) AS rn
    FROM birth_avg
)
SELECT
    "region",
    "country_name"           AS "highest_avg_birth_rate_country",
    ROUND(avg_birth_rate, 4) AS "average_crude_birth_rate_1980s"
FROM ranked
WHERE rn = 1
ORDER BY "region";