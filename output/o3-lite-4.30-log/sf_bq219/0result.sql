WITH mo_tot AS (     -- total liters sold each month (Jan‑2022 → last full month)
    SELECT
        TO_CHAR("date", 'YYYY-MM')    AS ym,
        SUM("volume_sold_liters")     AS mo_total
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY ym
),
cat_pct AS (         -- every category’s share (%) of that month’s total
    SELECT
        TO_CHAR(s."date", 'YYYY-MM')  AS ym,
        s."category_name",
        SUM(s."volume_sold_liters") / MAX(t.mo_total) * 100  AS pct_of_month
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES s
    JOIN mo_tot t
      ON TO_CHAR(s."date", 'YYYY-MM') = t.ym
    WHERE s."date" >= '2022-01-01'
      AND s."date" < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY
        TO_CHAR(s."date", 'YYYY-MM'),
        s."category_name"
),
eligible AS (        -- categories present ≥24 months & averaging ≥1 % share
    SELECT "category_name"
    FROM cat_pct
    GROUP BY "category_name"
    HAVING COUNT(*) >= 24
       AND AVG(pct_of_month) >= 1
),
filt AS (            -- monthly % only for eligible categories
    SELECT c.*
    FROM cat_pct c
    JOIN eligible e USING ("category_name")
),
pair_corr AS (       -- Pearson correlation for every ordered pair of categories
    SELECT
        f1."category_name"                        AS category_1,
        f2."category_name"                        AS category_2,
        CORR(f1.pct_of_month, f2.pct_of_month)    AS pearson_correlation
    FROM filt f1
    JOIN filt f2
      ON f1.ym = f2.ym
     AND f1."category_name" < f2."category_name"
    GROUP BY
        f1."category_name",
        f2."category_name"
)
SELECT
    category_1                     AS "category_1",
    category_2                     AS "category_2",
    ROUND(pearson_correlation, 4)  AS "pearson_correlation"
FROM pair_corr
ORDER BY pearson_correlation ASC NULLS LAST      -- lowest correlation first
LIMIT 1;