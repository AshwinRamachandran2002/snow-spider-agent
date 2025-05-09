WITH amplification_counts AS (
    SELECT
        c."cytoband_name",
        COUNT(*) AS "amplification_count"
    FROM
        "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
    JOIN
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
        ON c."chromosome" = s."chromosome"
        AND c."hg38_start" <= s."end_pos"
        AND c."hg38_stop" >= s."start_pos"
    WHERE
        s."project_short_name" = 'TCGA-KIRC'
        AND s."chromosome" = 'chr1'
        AND s."copy_number" > 3
    GROUP BY
        c."cytoband_name"
),
amplification_ranked AS (
    SELECT
        "cytoband_name",
        "amplification_count",
        RANK() OVER (
            ORDER BY
                "amplification_count" DESC NULLS LAST
        ) AS amplification_rank
    FROM
        amplification_counts
),
gain_counts AS (
    SELECT
        c."cytoband_name",
        COUNT(*) AS "gain_count"
    FROM
        "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
    JOIN
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
        ON c."chromosome" = s."chromosome"
        AND c."hg38_start" <= s."end_pos"
        AND c."hg38_stop" >= s."start_pos"
    WHERE
        s."project_short_name" = 'TCGA-KIRC'
        AND s."chromosome" = 'chr1'
        AND s."copy_number" = 3
    GROUP BY
        c."cytoband_name"
),
gain_ranked AS (
    SELECT
        "cytoband_name",
        "gain_count",
        RANK() OVER (
            ORDER BY
                "gain_count" DESC NULLS LAST
        ) AS gain_rank
    FROM
        gain_counts
),
deletion_counts AS (
    SELECT
        c."cytoband_name",
        COUNT(*) AS "deletion_count"
    FROM
        "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" c
    JOIN
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
        ON c."chromosome" = s."chromosome"
        AND c."hg38_start" <= s."end_pos"
        AND c."hg38_stop" >= s."start_pos"
    WHERE
        s."project_short_name" = 'TCGA-KIRC'
        AND s."chromosome" = 'chr1'
        AND s."copy_number" = 1
    GROUP BY
        c."cytoband_name"
),
deletion_ranked AS (
    SELECT
        "cytoband_name",
        "deletion_count",
        RANK() OVER (
            ORDER BY
                "deletion_count" DESC NULLS LAST
        ) AS deletion_rank
    FROM
        deletion_counts
),
combined AS (
    SELECT
        a."cytoband_name"
    FROM
        amplification_ranked a
    JOIN
        gain_ranked g ON a."cytoband_name" = g."cytoband_name"
    JOIN
        deletion_ranked d ON a."cytoband_name" = d."cytoband_name"
    WHERE
        a.amplification_rank <= 11
        AND g.gain_rank <= 11
        AND d.deletion_rank <= 11
)
SELECT DISTINCT
    "cytoband_name"
FROM
    combined;