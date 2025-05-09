WITH state_asset_sums AS (
    SELECT
        "state_name",
        SUM(COALESCE("total_assets", 0)) AS "total_assets_sum"
    FROM FDA.FDIC_BANKS.INSTITUTIONS
    WHERE "institution_name" ILIKE 'Bank%'        -- names starting with 'Bank'
      AND "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
    GROUP BY "state_name"
), max_asset_state AS (
    SELECT "state_name"
    FROM state_asset_sums
    ORDER BY "total_assets_sum" DESC NULLS LAST   -- state with highest summed assets
    LIMIT 1
)
SELECT COUNT(*) AS "total_number_of_institutions"
FROM FDA.FDIC_BANKS.INSTITUTIONS
WHERE "state_name" = (SELECT "state_name" FROM max_asset_state);