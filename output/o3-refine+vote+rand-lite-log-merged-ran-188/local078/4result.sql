WITH per_interest AS (
    SELECT 
        im.interest_id,
        im.month_year,
        im.composition,
        ROW_NUMBER() OVER (
            PARTITION BY im.interest_id 
            ORDER BY im.composition DESC, im._year, im._month
        ) AS rn
    FROM interest_metrics AS im
),
max_composition_per_interest AS (
    SELECT 
        interest_id,
        month_year,
        composition
    FROM per_interest
    WHERE rn = 1          -- keep the record with the highest composition per interest
),
named_compositions AS (
    SELECT 
        mci.month_year,
        imap.interest_name,
        mci.composition
    FROM max_composition_per_interest AS mci
    JOIN interest_map AS imap
      ON imap.id = mci.interest_id
),
top_ten AS (
    SELECT 
        month_year  AS "time(MM-YYYY)",
        interest_name,
        composition
    FROM named_compositions
    ORDER BY composition DESC, interest_name
    LIMIT 10
),
bottom_ten AS (
    SELECT 
        month_year  AS "time(MM-YYYY)",
        interest_name,
        composition
    FROM named_compositions
    ORDER BY composition ASC, interest_name
    LIMIT 10
)

SELECT * FROM top_ten
UNION ALL
SELECT * FROM bottom_ten;