WITH state_asset_sums AS (
    SELECT
        "state_name",
        SUM(COALESCE("total_assets", 0)) AS "sum_assets"
    FROM
        FDA.FDIC_BANKS.INSTITUTIONS
    WHERE
        "institution_name" ILIKE 'Bank%'                          -- names that start with 'Bank'
        AND "established_date" BETWEEN '1900-01-01' AND '2000-12-31'   -- establishments in the required period
    GROUP BY
        "state_name"
),
top_state AS (   -- state having the highest total assets among the filtered banks
    SELECT
        "state_name"
    FROM
        state_asset_sums
    ORDER BY
        "sum_assets" DESC NULLS LAST
    LIMIT 1
)
SELECT
    COUNT(*) AS "total_institutions"
FROM
    FDA.FDIC_BANKS.INSTITUTIONS inst
    JOIN top_state ts
      ON inst."state_name" = ts."state_name";