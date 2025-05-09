SELECT "url"
FROM (
    SELECT ps."project", ps."download_count", ps."latest_upload_time", SPLIT_PART(f.value::STRING, ', ', 2) AS "url"
    FROM (
        SELECT fd."project", COUNT(*) AS "download_count", MAX(dm."upload_time") AS "latest_upload_time", MAX(dm."project_urls") AS "project_urls"
        FROM "PYPI"."PYPI"."FILE_DOWNLOADS" fd
        JOIN "PYPI"."PYPI"."DISTRIBUTION_METADATA" dm ON fd."project" = dm."name"
        GROUP BY fd."project"
    ) ps, LATERAL FLATTEN(input => ps."project_urls") f
    WHERE SPLIT_PART(f.value::STRING, ', ', 2) ILIKE '%github.com%'
)
WHERE REGEXP_LIKE("url", '^https?://github\.com/[^/]+/[^/]+/?$')
ORDER BY "download_count" DESC NULLS LAST, "latest_upload_time" DESC NULLS LAST
LIMIT 1;