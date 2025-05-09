WITH per_interest_max AS (
    /* 1.  find the single month in which each interest category recorded its
           highest composition value  */
    SELECT
        im."interest_id",
        im."month_year",
        im."composition",
        ROW_NUMBER() OVER (
            PARTITION BY im."interest_id"
            ORDER BY im."composition" DESC
        ) AS rn
    FROM "interest_metrics" im
),
best_per_interest AS (
    /* 2. keep only that “best‐ever” record for every category */
    SELECT
        interest_id,
        month_year,
        composition
    FROM per_interest_max
    WHERE rn = 1
),
ranked AS (
    /* 3. rank those maxima from both the top and the bottom */
    SELECT
        bpi.interest_id,
        bpi.month_year,
        bpi.composition,
        imap.interest_name,
        RANK() OVER (ORDER BY bpi.composition DESC) AS rank_desc,
        RANK() OVER (ORDER BY bpi.composition ASC)  AS rank_asc
    FROM best_per_interest bpi
    JOIN "interest_map" imap
      ON imap.id = bpi.interest_id
),
top_bottom AS (
    /* 4. grab the 10 highest and 10 lowest records */
    SELECT 'Top'    AS grp, rank_desc AS pos, month_year, interest_name, composition
    FROM ranked
    WHERE rank_desc <= 10
    UNION ALL
    SELECT 'Bottom' AS grp, rank_asc  AS pos, month_year, interest_name, composition
    FROM ranked
    WHERE rank_asc  <= 10
)
SELECT
    month_year AS "time(MM-YYYY)",
    interest_name,
    composition
FROM top_bottom
ORDER BY grp, pos;