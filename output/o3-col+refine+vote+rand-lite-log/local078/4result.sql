WITH ranked AS (
    SELECT 
        im.month_year,
        im.interest_id,
        im.composition,
        ROW_NUMBER() OVER (
            PARTITION BY im.interest_id
            ORDER BY im.composition DESC
        ) AS rn
    FROM interest_metrics AS im
),
peaks AS (
    SELECT 
        month_year,
        interest_id,
        composition
    FROM ranked
    WHERE rn = 1
),
joined AS (
    SELECT
        p.month_year          AS time,
        mp.interest_name,
        ROUND(p.composition, 4) AS composition
    FROM peaks AS p
    JOIN interest_map AS mp
      ON p.interest_id = mp.id
),
top10 AS (
    SELECT *
    FROM joined
    ORDER BY composition DESC
    LIMIT 10
),
bottom10 AS (
    SELECT *
    FROM joined
    ORDER BY composition ASC
    LIMIT 10
)
SELECT *
FROM top10
UNION ALL
SELECT *
FROM bottom10;