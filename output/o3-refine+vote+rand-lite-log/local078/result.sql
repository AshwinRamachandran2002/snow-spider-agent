WITH max_composition_per_interest AS (
    /* 1.  Keep the row(s) where each interest_id records its
           highest composition value (if there is a tie, use the
           earliest month‑year). */
    SELECT
        im.interest_id,
        mp.interest_name,
        im.month_year,
        im.composition,
        ROW_NUMBER() OVER (
            PARTITION BY im.interest_id
            ORDER BY im.composition DESC, im._year, im._month          -- take earliest if tie
        ) AS rn
    FROM interest_metrics AS im
    JOIN interest_map      AS mp
      ON im.interest_id = mp.id
),
best_per_interest AS (
    /* 2. One record per interest category: its highest composition
           and the month‑year when it occurred. */
    SELECT
        interest_id,
        interest_name,
        month_year,
        composition
    FROM max_composition_per_interest
    WHERE rn = 1
),
top10 AS (
    /* 3. Ten largest of those maxima. */
    SELECT
        month_year,
        interest_name,
        composition
    FROM best_per_interest
    ORDER BY composition DESC, interest_name
    LIMIT 10
),
bottom10 AS (
    /* 4. Ten smallest of those maxima. */
    SELECT
        month_year,
        interest_name,
        composition
    FROM best_per_interest
    ORDER BY composition ASC, interest_name
    LIMIT 10
)
/* 5.  Return the requested rows (top followed by bottom). */
SELECT month_year, interest_name, composition FROM top10
UNION ALL
SELECT month_year, interest_name, composition FROM bottom10;