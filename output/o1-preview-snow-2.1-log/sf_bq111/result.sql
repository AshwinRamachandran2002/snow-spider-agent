WITH breast_cancer_freq AS (
    SELECT
        c."Chr" AS "chromosome",
        c."Type" AS "event_type",
        b."cytoband_name" AS "cytoband",
        COUNT(*) AS "breast_event_count"
    FROM
        "MITELMAN"."PROD"."CYTOCONVERTED" c
    JOIN
        "MITELMAN"."PROD"."CYTOGEN" g
        ON c."RefNo" = g."RefNo" AND c."CaseNo" = g."CaseNo"
    JOIN
        "MITELMAN"."PROD"."CYTOBANDS_HG38" b
        ON c."Chr" = b."chromosome"
        AND c."Start" <= b."hg38_stop"
        AND c."End" >= b."hg38_start"
    WHERE
        g."Morph" = '3111' AND g."Topo" = '0401'  -- Breast cancer morphology and topology codes
        AND c."Type" IN ('Gain', 'Loss')  -- Correct case for event types
    GROUP BY
        c."Chr",
        c."Type",
        b."cytoband_name"
),
other_cancer_freq AS (
    SELECT
        c."Chr" AS "chromosome",
        c."Type" AS "event_type",
        b."cytoband_name" AS "cytoband",
        COUNT(*) AS "other_event_count"
    FROM
        "MITELMAN"."PROD"."CYTOCONVERTED" c
    JOIN
        "MITELMAN"."PROD"."CYTOGEN" g
        ON c."RefNo" = g."RefNo" AND c."CaseNo" = g."CaseNo"
    JOIN
        "MITELMAN"."PROD"."CYTOBANDS_HG38" b
        ON c."Chr" = b."chromosome"
        AND c."Start" <= b."hg38_stop"
        AND c."End" >= b."hg38_start"
    WHERE
        NOT (g."Morph" = '3111' AND g."Topo" = '0401')  -- Exclude breast cancer cases
        AND c."Type" IN ('Gain', 'Loss')
    GROUP BY
        c."Chr",
        c."Type",
        b."cytoband_name"
),
combined_data AS (
    SELECT
        b."chromosome",
        b."event_type",
        b."cytoband",
        b."breast_event_count",
        o."other_event_count"
    FROM
        breast_cancer_freq b
    JOIN
        other_cancer_freq o
        ON b."chromosome" = o."chromosome"
        AND b."event_type" = o."event_type"
        AND b."cytoband" = o."cytoband"
)
SELECT
    "chromosome",
    "event_type",
    ROUND(CORR("breast_event_count", "other_event_count"), 4) AS "Pearson_correlation"
FROM
    combined_data
GROUP BY
    "chromosome",
    "event_type"
ORDER BY
    "chromosome",
    "event_type";