WITH KIRC_counts AS (
    SELECT
        cb."cytoband_name",
        SUM(CASE WHEN cnv."copy_number" > 3 THEN 1 ELSE 0 END) AS "amplification_count",
        SUM(CASE WHEN cnv."copy_number" = 3 THEN 1 ELSE 0 END) AS "gain_count",
        SUM(CASE WHEN cnv."copy_number" = 1 THEN 1 ELSE 0 END) AS "heterozygous_deletion_count"
    FROM
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" cnv
    JOIN
        "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" cb
        ON cnv."chromosome" = cb."chromosome"
        AND cnv."start_pos" <= cb."hg38_stop"
        AND cnv."end_pos" >= cb."hg38_start"
    WHERE
        cnv."chromosome" = 'chr1'
        AND cnv."project_short_name" = 'TCGA-KIRC'
    GROUP BY
        cb."cytoband_name"
),
MaxCopy AS (
    SELECT
        cb."cytoband_name",
        MAX(cnv."copy_number") AS "max_copy_number"
    FROM
        "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" cnv
    JOIN
        "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" cb
        ON cnv."chromosome" = cb."chromosome"
        AND cnv."start_pos" <= cb."hg38_stop"
        AND cnv."end_pos" >= cb."hg38_start"
    WHERE
        cnv."chromosome" = 'chr1'
        AND cnv."project_short_name" IN ('TCGA-KIRC', 'TCGA-KIRP', 'TCGA-KICH')
    GROUP BY
        cb."cytoband_name"
),
Combined AS (
    SELECT
        kc."cytoband_name",
        kc."amplification_count",
        kc."gain_count",
        kc."heterozygous_deletion_count",
        mc."max_copy_number"
    FROM
        KIRC_counts kc
    JOIN
        MaxCopy mc
            ON kc."cytoband_name" = mc."cytoband_name"
),
Ranked AS (
    SELECT
        c.*,
        RANK() OVER (ORDER BY c."amplification_count" DESC NULLS LAST, c."max_copy_number" DESC NULLS LAST) AS "amplification_rank",
        RANK() OVER (ORDER BY c."gain_count" DESC NULLS LAST, c."max_copy_number" DESC NULLS LAST) AS "gain_rank",
        RANK() OVER (ORDER BY c."heterozygous_deletion_count" DESC NULLS LAST, c."max_copy_number" DESC NULLS LAST) AS "heterozygous_deletion_rank"
    FROM
        Combined c
)
SELECT
    "cytoband_name"
FROM
    Ranked
WHERE
    "amplification_rank" <= 11
    AND "gain_rank" <= 11
    AND "heterozygous_deletion_rank" <= 11;