WITH best_per_category AS (
    /* Pick the month where each interest reached its maximum composition */
    SELECT
        im.interest_id,
        im.month_year,          -- already in MM‑YYYY format
        im.composition,
        ROW_NUMBER() OVER (
            PARTITION BY im.interest_id
            ORDER BY im.composition DESC, im._year, im._month    -- tie‑break with earliest month
        ) AS rn
    FROM interest_metrics AS im
),
max_composition_per_category AS (
    /* Keep only that maximum‑month row per interest */
    SELECT
        bpc.interest_id,
        bpc.month_year,
        bpc.composition,
        imap.interest_name
    FROM best_per_category AS bpc
    LEFT JOIN interest_map AS imap
           ON imap.id = bpc.interest_id
    WHERE bpc.rn = 1
),
ranked AS (
    /* Rank the interests by their max composition, both directions */
    SELECT
        *,
        RANK() OVER (ORDER BY composition DESC) AS rank_desc,
        RANK() OVER (ORDER BY composition ASC)  AS rank_asc
    FROM max_composition_per_category
),
top10 AS (
    SELECT
        1 AS section_order,
        month_year,
        COALESCE(interest_name,'Unknown') AS interest_name,
        composition
    FROM ranked
    WHERE rank_desc <= 10
),
bottom10 AS (
    SELECT
        2 AS section_order,
        month_year,
        COALESCE(interest_name,'Unknown') AS interest_name,
        composition
    FROM ranked
    WHERE rank_asc <= 10
)
SELECT
    month_year       AS "time(MM-YYYY)",
    interest_name,
    ROUND(composition,4) AS composition
FROM (
    SELECT * FROM top10
    UNION ALL
    SELECT * FROM bottom10
)
ORDER BY
    section_order,
    /* For section 1 (top list) we need descending composition,
       for section 2 (bottom list) ascending composition           */
    CASE
        WHEN section_order = 1 THEN -composition   -- negative flips the order to DESC
        ELSE  composition
    END,
    interest_name;