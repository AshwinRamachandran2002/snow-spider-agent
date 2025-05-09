WITH max_comp AS (                     -- 1. highest composition per interest_id
    SELECT
        "interest_id",
        MAX("composition") AS max_comp
    FROM "interest_metrics"
    GROUP BY "interest_id"
),
peak_month AS (                        -- 2. month(s) where that peak occurred
    SELECT
        im."month_year",
        im."interest_id",
        mc.max_comp AS composition_value
    FROM "interest_metrics" AS im
    JOIN max_comp          AS mc
      ON im."interest_id"  = mc."interest_id"
     AND im."composition"  = mc.max_comp
),
ranked AS (                            -- 3. attach interest names
    SELECT
        pm."month_year"    AS "time(MM-YYYY)",
        mp."interest_name",
        pm.composition_value
    FROM peak_month AS pm
    JOIN "interest_map" AS mp
      ON mp."id" = pm."interest_id"
)
-- 4. pick top‑10 and bottom‑10 by their peak composition values
SELECT *
FROM (
        SELECT *
        FROM ranked
        ORDER BY composition_value DESC, "interest_name"
        LIMIT 10
)
UNION ALL
SELECT *
FROM (
        SELECT *
        FROM ranked
        ORDER BY composition_value ASC, "interest_name"
        LIMIT 10
);