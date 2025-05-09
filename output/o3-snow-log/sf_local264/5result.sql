SELECT
    "L1_model",
    COUNT(*) AS "total_count"
FROM
    STACKING.STACKING.MODEL
GROUP BY
    "L1_model"
ORDER BY
    "total_count" DESC NULLS LAST
LIMIT 1;