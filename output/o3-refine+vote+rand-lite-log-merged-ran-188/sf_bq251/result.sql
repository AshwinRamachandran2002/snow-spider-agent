WITH latest_metadata AS (
    SELECT
        "name"                                       AS NAME,
        "upload_time",
        /* first GitHub‑looking URL in project_urls */
        REGEXP_SUBSTR(
            TO_VARCHAR("project_urls"),
            '(https?://github\\.com/[^"\\s\\}\\],]+)',
            1, 1, 'i'
        )                                            AS GITHUB_URL_RAW,
        ROW_NUMBER() OVER (PARTITION BY "name"
                           ORDER BY "upload_time" DESC) AS RN
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),
cleaned_metadata AS (
    /* newest version per package with a cleaned GitHub URL */
    SELECT
        NAME,
        REGEXP_REPLACE(
            GITHUB_URL_RAW,
            '(https?://github\\.com/[^/]+/[^/]+)(/.*)?',
            '\\1'
        )                                            AS CLEANED_GITHUB_URL
    FROM latest_metadata
    WHERE RN = 1
      AND GITHUB_URL_RAW IS NOT NULL
),
download_counts AS (
    SELECT
        "project"                                    AS NAME,
        COUNT(*)                                     AS DL_CNT
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY "project"
)
SELECT
    CLEANED_GITHUB_URL
FROM cleaned_metadata CM
JOIN download_counts DC
      ON LOWER(CM.NAME) = LOWER(DC.NAME)
ORDER BY DC.DL_CNT DESC NULLS LAST,
         CLEANED_GITHUB_URL
LIMIT 3;