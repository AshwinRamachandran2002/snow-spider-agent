WITH parsed AS (
    /* 1.  Read licenses (as JSON, if possible) for every package version */
    SELECT
        "System",
        TRY_PARSE_JSON("Licenses")      AS licenses_json
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
), flattened AS (
    /* 2.  One row per individual license string */
    SELECT
        "System",
        f.value::string                 AS license
    FROM parsed,
         LATERAL FLATTEN (input => licenses_json) f
    WHERE f.value IS NOT NULL           -- ignore empty / unparsable rows
), counts AS (
    /* 3.  Count how many times each license appears per system */
    SELECT
        "System",
        license,
        COUNT(*)                        AS cnt
    FROM flattened
    GROUP BY "System", license
), ranked AS (
    /* 4.  Rank licenses by frequency within each system */
    SELECT
        "System",
        license,
        cnt,
        ROW_NUMBER() OVER (PARTITION BY "System"
                           ORDER BY cnt DESC, license ASC) AS rn
    FROM counts
)
SELECT
    "System",
    license                          AS "MostFrequentLicense",
    cnt                              AS "LicenseCount"
FROM ranked
WHERE rn = 1     -- keep only the most frequent license per system
ORDER BY "System";