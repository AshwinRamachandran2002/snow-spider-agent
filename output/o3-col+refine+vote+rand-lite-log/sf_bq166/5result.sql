/*---------------------------------------------------------------------------
  Copy-number status frequencies per cytoband for TCGA-KIRC
---------------------------------------------------------------------------*/
WITH kirc_segments AS (          -- 1. all allele-specific CNV segments for KIRC
    SELECT
        s."case_barcode",
        s."chromosome",
        s."start_pos",
        s."end_pos",
        s."copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 s
    WHERE s."project_short_name" = 'TCGA-KIRC'
),
total_cases AS (                 -- 2. number of distinct KIRC cases
    SELECT COUNT(DISTINCT "case_barcode") AS "n_total_cases"
    FROM   kirc_segments
),
seg_band_overlap AS (            -- 3. segment ↔ cytoband overlaps
    SELECT
        k."case_barcode",
        b."chromosome",
        b."cytoband_name",
        k."copy_number",
        /* overlap length (bp) */
        GREATEST(
            0,
            LEAST(k."end_pos", b."hg38_stop")
              - GREATEST(k."start_pos", b."hg38_start")
        ) AS "overlap_bp",
        ROW_NUMBER() OVER (
            PARTITION BY k."case_barcode", b."cytoband_name"
            ORDER BY GREATEST(
                        0,
                        LEAST(k."end_pos", b."hg38_stop")
                          - GREATEST(k."start_pos", b."hg38_start")
                     ) DESC
        ) AS "rn"
    FROM   kirc_segments k
    JOIN   TCGA_MITELMAN.PROD.CYTOBANDS_HG38 b
           ON k."chromosome" = b."chromosome"
),
per_case_band AS (               -- 4. keep segment with largest overlap, retain max CN
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS "max_cn"
    FROM   seg_band_overlap
    WHERE  "rn" = 1
    GROUP  BY "case_barcode", "chromosome", "cytoband_name"
),
categorized AS (                 -- 5. classify CN state
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_cn" > 3 THEN 'Amplification'
            WHEN "max_cn" = 3 THEN 'Gain'
            WHEN "max_cn" = 2 THEN 'Normal'
            WHEN "max_cn" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_cn" = 0 THEN 'Homozygous Deletion'
        END AS "cn_subtype"
    FROM   per_case_band
),
freq AS (                        -- 6. count cases per cytoband & subtype
    SELECT
        "chromosome",
        "cytoband_name",
        "cn_subtype",
        COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM   categorized
    GROUP  BY "chromosome", "cytoband_name", "cn_subtype"
)
/*-------------------------------------------------------------------------*/
SELECT
    f."chromosome",
    f."cytoband_name",
    f."cn_subtype",
    f."n_cases",
    ROUND(100.0 * f."n_cases" / t."n_total_cases", 2) AS "percentage_cases"
FROM   freq f
CROSS  JOIN total_cases t
ORDER  BY
    /* chromosome ordering: chr1-22 → 1-22, chrX → 23, chrY → 24, chrM/chrMT → 25 */
    CASE
        WHEN REGEXP_REPLACE(f."chromosome", '^chr', '') = 'X'  THEN 23
        WHEN REGEXP_REPLACE(f."chromosome", '^chr', '') = 'Y'  THEN 24
        WHEN REGEXP_REPLACE(f."chromosome", '^chr', '') IN ('M','MT') THEN 25
        ELSE TRY_TO_NUMBER(REGEXP_REPLACE(f."chromosome", '^chr', ''))
    END,
    f."cytoband_name",
    f."cn_subtype";