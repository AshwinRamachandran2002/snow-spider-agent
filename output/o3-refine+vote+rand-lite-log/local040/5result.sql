WITH trees_income AS (
    SELECT
        t.boroname,
        i.Estimate_Mean_income
    FROM trees AS t
    LEFT JOIN income_trees AS i
        ON t.zipcode = i.zipcode          -- combine tree and income data by ZIP
    WHERE
        t.boroname IS NOT NULL            -- valid borough name
        AND t.boroname <> ''
        AND i.Estimate_Median_income > 0  -- keep rows with income data present
        AND i.Estimate_Mean_income  > 0
),
borough_stats AS (
    SELECT
        boroname,
        COUNT(*)                          AS tree_count,
        AVG(Estimate_Mean_income)         AS avg_mean_income
    FROM trees_income
    GROUP BY boroname
)
SELECT
    boroname,
    tree_count,
    avg_mean_income
FROM borough_stats
ORDER BY tree_count DESC, boroname
LIMIT 3;