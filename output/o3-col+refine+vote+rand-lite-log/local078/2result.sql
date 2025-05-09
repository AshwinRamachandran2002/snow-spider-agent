/* Top-10 and Bottom-10 interest categories by their single-highest composition value */
WITH max_per_interest AS (                 -- 1) each interest_id’s peak row
    SELECT
        interest_id,
        month_year,
        composition
    FROM (
        SELECT
            interest_id,
            month_year,
            composition,
            ROW_NUMBER() OVER (
                PARTITION BY interest_id
                ORDER BY composition DESC, month_year          -- highest first, earliest tie-break
            ) AS rn
        FROM interest_metrics
    )
    WHERE rn = 1                           -- keep only the peak row for each interest
),
top10 AS (                                 -- 2) 10 largest peaks
    SELECT *, 'TOP-10' AS grp
    FROM max_per_interest
    ORDER BY composition DESC
    LIMIT 10
),
bottom10 AS (                              -- 3) 10 smallest peaks
    SELECT *, 'BOTTOM-10' AS grp
    FROM max_per_interest
    ORDER BY composition ASC
    LIMIT 10
),
combined AS (                              -- 4) put them together
    SELECT * FROM top10
    UNION ALL
    SELECT * FROM bottom10
)
SELECT                                      -- 5) final output
    c.month_year       AS time,             -- MM-YYYY
    COALESCE(im.interest_name,'Unknown') AS interest_name,
    ROUND(c.composition,4)  AS composition, -- retain up to 4 decimals
    c.grp
FROM combined AS c
LEFT JOIN interest_map AS im
       ON c.interest_id = im.id
ORDER BY
    CASE WHEN c.grp = 'TOP-10' THEN 0 ELSE 1 END,      -- TOP-10 first
    c.composition * CASE WHEN c.grp = 'TOP-10' THEN -1 ELSE 1 END;