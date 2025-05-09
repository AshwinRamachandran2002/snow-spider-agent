WITH unicorns AS (
    /* 1.  Unicorns created between 2019‑2021 (valuation ≥ $1 B) with their industry and join year */
    SELECT
        cf.company_id,
        ci.industry,
        SUBSTR(cd.date_joined, 1, 4) AS join_year
    FROM companies_funding      AS cf
    JOIN companies_dates        AS cd ON cf.company_id = cd.company_id
    JOIN companies_industries   AS ci ON cf.company_id = ci.company_id
    WHERE cf.valuation >= 1000000000
      AND SUBSTR(cd.date_joined, 1, 4) BETWEEN '2019' AND '2021'
),
top_industry AS (
    /* 2.  Find the industry with the most new unicorns over 2019‑2021 */
    SELECT industry
    FROM unicorns
    GROUP BY industry
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
yearly_counts AS (
    /* 3.  Count new unicorns per year in that top industry */
    SELECT
        u.join_year,
        COUNT(*) AS cnt
    FROM unicorns u
    JOIN top_industry t ON u.industry = t.industry
    GROUP BY u.join_year
),
years AS (
    /* 4.  Ensure all three years are represented (missing ones count as 0) */
    SELECT '2019' AS join_year UNION ALL
    SELECT '2020' UNION ALL
    SELECT '2021'
)
SELECT
    ROUND(
        CAST(SUM(COALESCE(yc.cnt, 0)) AS FLOAT) / 3,
        4
    ) AS avg_new_unicorns_per_year
FROM years y
LEFT JOIN yearly_counts yc ON y.join_year = yc.join_year;