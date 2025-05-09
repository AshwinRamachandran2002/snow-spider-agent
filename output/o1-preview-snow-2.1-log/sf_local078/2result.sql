WITH max_compositions AS (
    SELECT
        m."interest_id",
        im."interest_name",
        m."month_year" AS "Time",
        ROUND(m."composition", 4) AS "Composition Value",
        ROW_NUMBER() OVER (PARTITION BY m."interest_id" ORDER BY m."composition" DESC NULLS LAST) AS rn
    FROM
        BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS" m
    JOIN
        BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP" im
        ON m."interest_id" = im."id"
)
SELECT
    mc."Time",
    mc."interest_name" AS "Interest Name",
    mc."Composition Value"
FROM (
    SELECT
        mc.*,
        ROW_NUMBER() OVER (ORDER BY mc."Composition Value" DESC NULLS LAST) AS rank_desc,
        ROW_NUMBER() OVER (ORDER BY mc."Composition Value" ASC NULLS LAST) AS rank_asc
    FROM
        max_compositions mc
    WHERE
        mc.rn = 1
) mc
WHERE
    mc.rank_desc <= 10 OR mc.rank_asc <= 10
ORDER BY
    mc.rank_desc;