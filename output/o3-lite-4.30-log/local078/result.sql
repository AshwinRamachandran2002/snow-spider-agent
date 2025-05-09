WITH ranked AS (
    SELECT
        im."interest_id",
        im."month_year",
        im."composition",
        ROW_NUMBER() OVER (
            PARTITION BY im."interest_id"
            ORDER BY im."composition" DESC, im."month_year"
        ) AS rn
    FROM "interest_metrics" im
),
best AS (                       -- one peak row per interest
    SELECT
        r."interest_id",
        r."month_year",
        r."composition"
    FROM ranked r
    WHERE r.rn = 1
),
best_named AS (
    SELECT
        b."month_year",
        m."interest_name",
        b."composition"
    FROM best b
    JOIN "interest_map" m
      ON b."interest_id" = m."id"
),
top AS (                        -- 10 highest‑scoring interests
    SELECT
        bn."month_year",
        bn."interest_name",
        bn."composition",
        1 AS grp,
        ROW_NUMBER() OVER (ORDER BY bn."composition" DESC, bn."interest_name") AS pos
    FROM best_named bn
    ORDER BY bn."composition" DESC
    LIMIT 10
),
bottom AS (                     -- 10 lowest‑scoring interests
    SELECT
        bn."month_year",
        bn."interest_name",
        bn."composition",
        2 AS grp,
        ROW_NUMBER() OVER (ORDER BY bn."composition" ASC, bn."interest_name") AS pos
    FROM best_named bn
    ORDER BY bn."composition" ASC
    LIMIT 10
),
combined AS (
    SELECT * FROM top
    UNION ALL
    SELECT * FROM bottom
)
SELECT
    "month_year" AS time,
    "interest_name",
    printf('%.4f',"composition") AS composition_value
FROM combined
ORDER BY grp, pos;