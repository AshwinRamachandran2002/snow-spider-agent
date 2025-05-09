WITH state_assets AS (
    SELECT
        "state_name",
        SUM(COALESCE("total_assets", 0)) AS sum_assets
    FROM FDA.FDIC_BANKS.INSTITUTIONS
    WHERE "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
      AND UPPER("institution_name") LIKE 'BANK%'
    GROUP BY "state_name"
),
top_state AS (
    SELECT
        "state_name"
    FROM state_assets
    QUALIFY ROW_NUMBER() OVER (ORDER BY sum_assets DESC NULLS LAST) = 1
)
SELECT
    COUNT(*) AS "total_number_of_institutions"
FROM FDA.FDIC_BANKS.INSTITUTIONS i
JOIN top_state ts
  ON i."state_name" = ts."state_name";