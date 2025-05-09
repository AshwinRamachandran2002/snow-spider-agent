WITH params AS (
    /* analysis period: 2022-01-01 through the last fully-completed month */
    SELECT
        DATE '2022-01-01'                       AS start_date ,
        DATE_TRUNC('month', CURRENT_DATE())     AS current_month_start
),

/* total litres sold by category for each month in the period */
base AS (
    SELECT
        DATE_TRUNC('month', s."date") AS month ,
        s."category_name"             AS category_name ,
        SUM(s."volume_sold_liters")   AS cat_volume
    FROM
        IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES s ,
        params
    WHERE
        s."date" >= params.start_date
        AND s."date" <  params.current_month_start
    GROUP BY
        1 , 2
),

/* distinct months and categories present in the base data */
months         AS (SELECT DISTINCT month          FROM base),
all_categories AS (SELECT DISTINCT category_name FROM base),

/* total litres sold across all categories for every month */
totals AS (
    SELECT
        month ,
        SUM(cat_volume) AS total_volume
    FROM
        base
    GROUP BY
        month
),

/* percentage contribution for every category in every month (0 when no sales) */
percentage AS (
    SELECT
        m.month ,
        c.category_name ,
        COALESCE(b.cat_volume , 0)            AS cat_volume ,
        t.total_volume ,
        COALESCE(b.cat_volume , 0) / t.total_volume AS perc
    FROM
        months m
        CROSS JOIN all_categories c
        LEFT JOIN base   b ON m.month = b.month AND c.category_name = b.category_name
        JOIN totals t    ON m.month = t.month
),

/* keep categories that (a) sold in ≥24 months and (b) average ≥1 % of monthly volume */
cat_stats AS (
    SELECT
        category_name ,
        COUNT_IF(cat_volume > 0) AS months_present ,
        AVG(perc)                AS avg_pct
    FROM
        percentage
    GROUP BY
        category_name
    HAVING
        months_present >= 24
        AND avg_pct      >= 0.01
),

/* monthly percentage series for qualifying categories */
filtered AS (
    SELECT
        p.month ,
        p.category_name ,
        p.perc
    FROM
        percentage p
        JOIN cat_stats cs ON p.category_name = cs.category_name
),

/* pair-wise Pearson correlations between qualifying categories */
pairs AS (
    SELECT
        f1.category_name                     AS cat1 ,
        f2.category_name                     AS cat2 ,
        CORR(f1.perc , f2.perc)              AS corr
    FROM
        filtered f1
        JOIN filtered f2
          ON  f1.month          = f2.month
          AND f1.category_name  < f2.category_name   -- avoid duplicates & self-pairs
    GROUP BY
        cat1 , cat2
),

/* pick the pair with the lowest correlation coefficient */
ordered AS (
    SELECT
        cat1 ,
        cat2 ,
        corr ,
        ROW_NUMBER() OVER (ORDER BY corr ASC) AS rn
    FROM
        pairs
)

SELECT
    cat1 AS "CATEGORY_1" ,
    cat2 AS "CATEGORY_2"
FROM
    ordered
WHERE
    rn = 1;