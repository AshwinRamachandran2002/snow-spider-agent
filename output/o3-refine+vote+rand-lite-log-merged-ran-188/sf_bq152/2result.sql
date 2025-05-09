/* ---------------------------------------------------------------
   BRCA (TCGA-BRCA) copy-number landscape by chromosome
   ‑ Uses masked copy-number segments (Release-14 ≈ GDC R23).
   ‑ For every case and chromosome:
        • overlap-weighted average absolute copy number
          CN = 2*2^(segment_mean)
        • round to nearest whole copy number
        • map to CNV class
   ‑ For every chromosome:
        • % of BRCA cases in each CNV class
-----------------------------------------------------------------*/
WITH segments AS (               -- BRCA copy-number segments
    SELECT
        "case_barcode",
        "chromosome"                       AS "chrom",
        "start_pos"                        AS "seg_start",
        "end_pos"                          AS "seg_end",
        "segment_mean"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."COPY_NUMBER_SEGMENT_MASKED_R14"
    WHERE "project_short_name" = 'TCGA-BRCA'
), chrom_sizes AS (              -- per-chromosome size (bp) from segments
    SELECT
        "chrom",
        MAX("seg_end") AS "chrom_end_bp"
    FROM segments
    GROUP BY "chrom"
), chrom_case_overlap AS (       -- bp overlap (always full segment here)
    SELECT
        s."case_barcode",
        s."chrom",
        s."segment_mean",
        (s."seg_end" - s."seg_start" + 1) AS "overlap_bp"
    FROM segments s
), chrom_case_cn AS (            -- weighted mean CN per chromosome + case
    SELECT
        "case_barcode",
        "chrom",
        ROUND(
            SUM( (2 * POWER(2, "segment_mean")) * "overlap_bp")
            / NULLIF(SUM("overlap_bp"),0)
        )                        AS "round_cn"
    FROM chrom_case_overlap
    GROUP BY "case_barcode","chrom"
), chrom_case_class AS (         -- map to CNV category
    SELECT
        *,
        CASE
            WHEN "round_cn" = 0 THEN 'Homozygous Deletion'
            WHEN "round_cn" = 1 THEN 'Heterozygous Deletion'
            WHEN "round_cn" = 2 THEN 'Diploid'
            WHEN "round_cn" = 3 THEN 'Gain'
            WHEN "round_cn"  > 3 THEN 'Amplification'
            ELSE 'Unknown'
        END AS "cnv_type"
    FROM chrom_case_cn
), total_cases AS (              -- # unique BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM   chrom_case_class
)
SELECT
    c."chrom"                                            AS "chromosome",
    1                                                    AS "start_bp",
    cs."chrom_end_bp"                                    AS "end_bp",
    ROUND(100.0 * COUNT_IF(c."cnv_type"='Homozygous Deletion')   / tc."n_cases", 2) AS "pct_homo_del",
    ROUND(100.0 * COUNT_IF(c."cnv_type"='Heterozygous Deletion') / tc."n_cases", 2) AS "pct_het_del",
    ROUND(100.0 * COUNT_IF(c."cnv_type"='Diploid')               / tc."n_cases", 2) AS "pct_normal",
    ROUND(100.0 * COUNT_IF(c."cnv_type"='Gain')                  / tc."n_cases", 2) AS "pct_gain",
    ROUND(100.0 * COUNT_IF(c."cnv_type"='Amplification')         / tc."n_cases", 2) AS "pct_amp"
FROM  chrom_case_class c
JOIN  chrom_sizes cs  ON cs."chrom" = c."chrom"
CROSS JOIN total_cases tc
GROUP BY c."chrom", cs."chrom_end_bp", tc."n_cases"
ORDER BY LPAD(c."chrom",3,'0');      -- ensures chr1, chr2, ..., chrX