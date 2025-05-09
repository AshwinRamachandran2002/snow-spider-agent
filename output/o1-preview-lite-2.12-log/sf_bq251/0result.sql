SELECT pu.value::STRING AS "GitHub_URL"
FROM (
    SELECT fd."project", COUNT(*) AS "download_count", MAX(dm."upload_time") AS "latest_upload_time"
    FROM PYPI.PYPI.FILE_DOWNLOADS fd
    JOIN PYPI.PYPI.DISTRIBUTION_METADATA dm ON fd."project" = dm."name"
    GROUP BY fd."project"
) stats
JOIN PYPI.PYPI.DISTRIBUTION_METADATA dm ON stats."project" = dm."name"
JOIN LATERAL FLATTEN(input => dm."project_urls") pu
WHERE pu.value::STRING ILIKE '%github.com%'
  AND pu.value::STRING NOT ILIKE '%/issues%'
  AND pu.value::STRING NOT ILIKE '%/blob%'
  AND pu.value::STRING NOT ILIKE '%/pulls%'
  AND pu.value::STRING NOT ILIKE '%/tree%'
ORDER BY stats."download_count" DESC NULLS LAST, stats."latest_upload_time" DESC NULLS LAST
LIMIT 1;