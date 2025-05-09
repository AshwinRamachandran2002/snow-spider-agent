SELECT
  ROUND(COUNT(*) / 3.0, 4) AS "Average_new_unicorn_companies_per_year_in_top_industry"
FROM MODERN_DATA.MODERN_DATA."COMPANIES_DATES" AS c
JOIN MODERN_DATA.MODERN_DATA."COMPANIES_INDUSTRIES" AS i
  ON c."company_id" = i."company_id"
WHERE EXTRACT(
        YEAR FROM TO_TIMESTAMP(c."date_joined", 'YYYY-MM-DD"T"HH24:MI:SS.FF3')
      ) BETWEEN 2019 AND 2021
  AND i."industry" = (
    SELECT i2."industry"
    FROM MODERN_DATA.MODERN_DATA."COMPANIES_DATES" AS c2
    JOIN MODERN_DATA.MODERN_DATA."COMPANIES_INDUSTRIES" AS i2
      ON c2."company_id" = i2."company_id"
    WHERE EXTRACT(
            YEAR FROM TO_TIMESTAMP(c2."date_joined", 'YYYY-MM-DD"T"HH24:MI:SS.FF3')
          ) BETWEEN 2019 AND 2021
    GROUP BY i2."industry"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
  );