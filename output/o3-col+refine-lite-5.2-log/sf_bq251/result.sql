-- Top‑3 most‑downloaded PyPI packages that expose a GitHub repository URL
WITH latest_version AS (                                                      -- 1. keep only newest metadata row per package
    SELECT *
    FROM   "PYPI"."PYPI"."DISTRIBUTION_METADATA"
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "name" ORDER BY "upload_time" DESC) = 1
),
github_links AS (                                                             -- 2. explode project_urls & keep github refs, clean them
    SELECT
        lv."name",
        -- keep only the URL part, strip “issues|pull|blob|tree …”
        REGEXP_REPLACE(                                                     
            REGEXP_REPLACE(LOWER(f.value::STRING),
                           '.*?(https://github\.com/)',                       -- drop any label before the URL
                           'https://github.com/'),
            '/(issues|pull|blob|tree)(/.*)?',
            ''
        )           AS "clean_url"
    FROM   latest_version lv,
           LATERAL FLATTEN(input => lv."project_urls") f
    WHERE  f.value::STRING ILIKE '%github.com%'
),
download_totals AS (                                                          -- 3. total downloads per project
    SELECT  "project" AS "name",
            COUNT(*)  AS "download_cnt"
    FROM    "PYPI"."PYPI"."FILE_DOWNLOADS"
    GROUP BY "project"
),
per_project AS (                                                              -- 4. one cleaned URL per project
    SELECT
        gl."name",
        MIN(gl."clean_url") AS "clean_url",                                   -- choose any (already cleaned)
        dt."download_cnt"
    FROM   github_links   gl
    JOIN   download_totals dt USING ("name")
    GROUP BY gl."name", dt."download_cnt"
)
SELECT  "clean_url"
FROM    per_project
ORDER BY "download_cnt" DESC NULLS LAST
LIMIT 3;