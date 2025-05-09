WITH filtered AS (
    SELECT
        "state",
        SUM("total_assets") AS sum_assets
    FROM FDA.FDIC_BANKS.INSTITUTIONS
    WHERE "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
      AND "institution_name" ILIKE 'Bank%'
    GROUP BY "state"
),
top_state AS (
    SELECT "state"
    FROM filtered
    ORDER BY sum_assets DESC NULLS LAST
    LIMIT 1
)
SELECT
    COUNT(*) AS total_institutions
FROM FDA.FDIC_BANKS.INSTITUTIONS AS i
JOIN top_state ts
  ON i."state" = ts."state";