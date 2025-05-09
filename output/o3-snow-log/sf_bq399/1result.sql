WITH country_birth_80s AS (   -- average 1980-1989 crude birth-rate for each high-income country
    SELECT
        hp."country_code",
        hp."country_name",
        AVG(hp."value") AS AVG_BIRTH_RATE
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION hp
    JOIN WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.COUNTRY_SUMMARY cs
          ON hp."country_code" = cs."country_code"
    WHERE hp."indicator_code" = 'SP.DYN.CBRT.IN'      -- crude birth rate
      AND hp."year" BETWEEN 1980 AND 1989             -- the 1980s
      AND cs."income_group" ILIKE 'High income%'      -- high-income economies only
      AND cs."region" IS NOT NULL                     -- exclude aggregates
    GROUP BY hp."country_code", hp."country_name"
), ranked AS (        -- select country with highest average in each region
    SELECT
        cs."region",
        cb."country_name",
        cb.AVG_BIRTH_RATE,
        ROW_NUMBER() OVER (PARTITION BY cs."region"
                           ORDER BY cb.AVG_BIRTH_RATE DESC NULLS LAST) AS rn
    FROM country_birth_80s cb
    JOIN WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.COUNTRY_SUMMARY cs
          ON cb."country_code" = cs."country_code"
)
SELECT
    "region",
    "country_name",
    ROUND(AVG_BIRTH_RATE, 4) AS "average_crude_birth_rate_1980s"
FROM ranked
WHERE rn = 1
ORDER BY "region";