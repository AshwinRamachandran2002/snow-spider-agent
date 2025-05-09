WITH overlap AS (
    SELECT
        s."case_barcode",
        /* convert segment_mean (log2 ratio) to absolute copy-number */
        POWER(2, s."segment_mean") * 2                          AS "segment_copy_number",
        /* base-pair overlap length between segment and cytoband region */
        ( LEAST(s."end_pos",   c."hg38_stop")
        - GREATEST(s."start_pos", c."hg38_start") + 1 )         AS "overlap_len"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14  s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                     c
         ON c."chromosome"    = 'chr15'               -- cytoband chromosome
        AND c."cytoband_name" ILIKE '15q11%'          -- all 15q11 sub-bands
        AND s."chromosome"    = '15'                  -- segment chromosome
        AND s."start_pos"    <= c."hg38_stop"         -- overlap condition
        AND s."end_pos"      >= c."hg38_start"
    WHERE s."project_short_name" = 'TCGA-LAML'        -- LAML study only
),
per_case AS (
    SELECT
        "case_barcode",
        SUM("segment_copy_number" * "overlap_len") 
        /  NULLIF(SUM("overlap_len"),0)               AS "weighted_avg_copy_number"
    FROM overlap
    GROUP BY "case_barcode"
)
SELECT
    "case_barcode",
    "weighted_avg_copy_number"
FROM per_case
ORDER BY "weighted_avg_copy_number" DESC NULLS LAST
LIMIT 20;