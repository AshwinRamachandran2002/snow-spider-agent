WITH state_asset_totals AS (
    -- 1.  Sum assets of “Bank%” institutions established 1900-2000, by state
    SELECT
        state,
        SUM(IFNULL(total_assets,0)) AS summed_assets
    FROM `bigquery-public-data.fdic_banks.institutions`
    WHERE LOWER(institution_name) LIKE 'bank%'                -- name starts with “Bank”
      AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
    GROUP BY state
),
top_state AS (
    -- 2.  Pick the state(s) with the largest summed assets
    SELECT state
    FROM state_asset_totals
    QUALIFY RANK() OVER (ORDER BY summed_assets DESC) = 1     -- highest asset total
)
-- 3.  Count ALL banking institutions (any name, any date) located in that state
SELECT
    COUNT(DISTINCT fdic_certificate_number) AS total_institutions
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state IN (SELECT state FROM top_state);