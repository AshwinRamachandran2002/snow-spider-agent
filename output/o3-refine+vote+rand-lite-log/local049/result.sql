WITH unicorns AS (
    /* 1.  All companies that became unicorns (valuation ≥ $1 B) in 2019‑2021 */
    SELECT
        cf.company_id,
        ci.industry,
        SUBSTR(cd.date_joined,1,4) AS year               -- extract YYYY
    FROM companies_funding      AS cf
    JOIN companies_dates        AS cd ON cf.company_id = cd.company_id
    JOIN companies_industries   AS ci ON cf.company_id = ci.company_id
    WHERE cf.valuation >= 1000000000
      AND SUBSTR(cd.date_joined,1,4) BETWEEN '2019' AND '2021'
),
industry_totals AS (
    /* 2.  Total new‑unicorn count per industry over the whole period */
    SELECT
        industry,
        COUNT(*) AS total_new
    FROM unicorns
    GROUP BY industry
),
top_industry AS (
    /* 3.  Industry with the most new unicorns (tie‑broken alphabetically) */
    SELECT industry
    FROM industry_totals
    ORDER BY total_new DESC, industry
    LIMIT 1
),
industry_year_counts AS (
    /* 4.  Yearly counts for the top industry */
    SELECT
        year,
        COUNT(*) AS new_unicorns
    FROM unicorns
    WHERE industry = (SELECT industry FROM top_industry)
    GROUP BY year
),
years AS (
    /* 5.  Ensure every year 2019–2021 is present (fill missing with 0) */
    SELECT '2019' AS year UNION ALL
    SELECT '2020' UNION ALL
    SELECT '2021'
),
year_counts_complete AS (
    SELECT
        y.year,
        COALESCE(iyc.new_unicorns,0) AS new_unicorns
    FROM years y
    LEFT JOIN industry_year_counts iyc USING (year)
)
SELECT
    AVG(new_unicorns) AS avg_new_unicorns_per_year
FROM year_counts_complete;