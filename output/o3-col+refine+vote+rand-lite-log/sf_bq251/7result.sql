WITH latest AS (  -- most-recent metadata per package
    SELECT *
    FROM (
        SELECT  dm.*,
                ROW_NUMBER() OVER (PARTITION BY dm."name" ORDER BY dm."upload_time" DESC) AS rn
        FROM    PYPI.PYPI.DISTRIBUTION_METADATA dm
    )
    WHERE rn = 1
),
github_urls AS (  -- extract & clean GitHub repository URLs
    SELECT
        l."name"                                                        AS pkg_name,
        REGEXP_REPLACE(
            REGEXP_SUBSTR(f.value::STRING, 'https://github[^\s,)"]+'),
            '/(issues|pulls?|pull|blob|tree).*$',                       -- drop extra paths
            ''
        )                                                               AS github_repo
    FROM   latest l,
           LATERAL FLATTEN(input => l."project_urls") f
    WHERE  f.value ILIKE '%github%'
),
downloads AS (  -- total download counts per package
    SELECT  "project"                         AS pkg_name,
            COUNT(*)                          AS download_cnt
    FROM    PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
),
ranked AS (  -- rank packages by download count
    SELECT  DISTINCT
            g.github_repo,
            d.download_cnt,
            ROW_NUMBER() OVER (ORDER BY d.download_cnt DESC NULLS LAST) AS rn
    FROM    github_urls g
    JOIN    downloads   d  ON g.pkg_name = d.pkg_name
)
SELECT github_repo
FROM   ranked
WHERE  rn <= 3
ORDER BY rn;