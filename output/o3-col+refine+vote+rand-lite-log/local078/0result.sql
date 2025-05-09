WITH max_comp_per_interest AS (
    -- highest composition each interest ever reached
    SELECT
        "interest_id",
        MAX("composition") AS max_comp
    FROM "interest_metrics"
    GROUP BY "interest_id"
),
max_month AS (
    -- the month-year when that maximum was observed
    SELECT
        im."month_year",
        im."interest_id",
        im."composition"
    FROM "interest_metrics" AS im
    JOIN max_comp_per_interest AS mc
      ON  im."interest_id" = mc."interest_id"
      AND im."composition"  = mc.max_comp
),
named_max AS (
    -- attach readable category names
    SELECT
        mm."month_year",
        COALESCE(imap."interest_name", 'unknown') AS interest_name,
        mm."composition"
    FROM max_month AS mm
    LEFT JOIN "interest_map" AS imap
           ON imap."id" = mm."interest_id"
)
-- return top 10 and bottom 10 by their highest composition
SELECT "month_year", "interest_name", "composition"
FROM (
    SELECT * FROM named_max
    ORDER BY "composition" DESC
    LIMIT 10
)
UNION ALL
SELECT "month_year", "interest_name", "composition"
FROM (
    SELECT * FROM named_max
    ORDER BY "composition" ASC
    LIMIT 10
);