WITH ranked_interest AS (
    /* 1.  Pick the month in which each interest reached its
           highest composition value                         */
    SELECT
        im.interest_id,
        mp.interest_name,
        im.month_year,
        im.composition,
        ROW_NUMBER() OVER (
            PARTITION BY im.interest_id
            ORDER BY im.composition DESC,                -- highest composition first
                     im.month_year                       -- if tie, earliest month‑year
        ) AS rn
    FROM interest_metrics AS im
    JOIN interest_map      AS mp
          ON im.interest_id = mp.id
),
peak_interest AS (
    /* 2.  Keep the single (highest) row for every interest */
    SELECT
        interest_name,
        month_year,
        composition
    FROM ranked_interest
    WHERE rn = 1
),
top10 AS (
    /* 3a. Ten interests with the largest peak compositions */
    SELECT
        1               AS seq_order,     -- to keep “top” rows ahead of “bottom” rows
        month_year,
        interest_name,
        composition
    FROM peak_interest
    ORDER BY composition DESC, interest_name
    LIMIT 10
),
bottom10 AS (
    /* 3b. Ten interests with the smallest peak compositions */
    SELECT
        2               AS seq_order,
        month_year,
        interest_name,
        composition
    FROM peak_interest
    ORDER BY composition ASC, interest_name
    LIMIT 10
)
SELECT
    month_year,          -- MM‑YYYY of the highest composition
    interest_name,       -- category name
    composition          -- highest composition value
FROM (
    SELECT * FROM top10
    UNION ALL
    SELECT * FROM bottom10
)
/* 4. Present “top” interests first (by descending composition),
      then “bottom” interests (by ascending composition)          */
ORDER BY
    seq_order,
    CASE WHEN seq_order = 1 THEN -composition ELSE composition END,
    interest_name;