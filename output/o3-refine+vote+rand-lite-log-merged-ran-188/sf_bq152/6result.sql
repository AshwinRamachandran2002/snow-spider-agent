/* ============================================================================
   Chromosome-level CNV profile for TCGA-BRCA                                
   ---------------------------------------------------------------------------
   No external cytoband table is required – each chromosome is treated as one
   “band”.  Boundaries are taken from the BRCA masked copy-number segments
   themselves (R14 release).  The query therefore runs with only the data that
   are guaranteed to exist in this environment.
   ---------------------------------------------------------------------------
   CNV category (after rounding absolute copy number):
        0  → Homozygous Deletion
        1  → Heterozygous Deletion
        2  → Diploid (normal)
        3  → Gain
        >3 → Amplification
   Output: one row per chromosome with % frequency of each CNV type.
   ============================================================================ */

WITH brca_seg AS (                       -- masked CN segments for TCGA-BRCA
    SELECT
        REGEXP_REPLACE("chromosome", '^chr', '')  AS "chrom",
        "start_pos"                               AS "seg_start",
        "end_pos"                                 AS "seg_end",
        "segment_mean",
        "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED_R14"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

chrom_bounds AS (                         -- min / max co-ordinates per chr
    SELECT
        "chrom",
        MIN("seg_start") AS "band_start",
        MAX("seg_end")   AS "band_end"
    FROM brca_seg
    GROUP BY "chrom"
),

bands AS (                                -- treat a whole chromosome as band
    SELECT
        "chrom",
        "chrom"                AS "band",     -- e.g., '1','2', … ,'X','Y'
        "band_start",
        "band_end"
    FROM chrom_bounds
),

overlap AS (                              -- segment ↔ band overlap length
    SELECT
        b."band",
        b."band_start",
        b."band_end",
        s."case_barcode",
        LEAST(b."band_end",  s."seg_end")
      - GREATEST(b."band_start", s."seg_start") + 1     AS "ov_len",
        s."segment_mean"
    FROM bands b
    JOIN brca_seg s
      ON b."chrom" = s."chrom"
),

band_case_avg AS (                        -- overlap-weighted mean seg_mean
    SELECT
        "band",
        "band_start",
        "band_end",
        "case_barcode",
        SUM("ov_len" * "segment_mean") / SUM("ov_len")  AS "w_seg_mean"
    FROM overlap
    GROUP BY "band","band_start","band_end","case_barcode"
),

band_case_copynum AS (                    -- absolute copy number (rounded)
    SELECT
        "band",
        "band_start",
        "band_end",
        "case_barcode",
        ROUND( 2 * POWER(2, "w_seg_mean") )  AS "copy_number"
    FROM band_case_avg
),

band_case_cnv AS (                        -- CNV label per (band, case)
    SELECT
        "band",
        "band_start",
        "band_end",
        CASE
            WHEN "copy_number" = 0 THEN 'Homozygous Deletion'
            WHEN "copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "copy_number" = 2 THEN 'Diploid'
            WHEN "copy_number" = 3 THEN 'Gain'
            ELSE                       'Amplification'
        END  AS "cnv_type"
    FROM band_case_copynum
),

case_cnt AS (                             -- total # BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM band_case_copynum
),

freq AS (                                 -- % frequency of each CNV type
    SELECT
        bc."band",
        bc."band_start",
        bc."band_end",
        bc."cnv_type",
        ROUND(100.0 * COUNT(*) / cc."n_cases", 2) AS "pct"
    FROM band_case_cnv bc
    CROSS JOIN case_cnt cc
    GROUP BY bc."band",bc."band_start",bc."band_end",bc."cnv_type",cc."n_cases"
)

SELECT
    "band"        AS "chromosome",
    "band_start",
    "band_end",
    COALESCE(MAX(CASE WHEN "cnv_type" = 'Homozygous Deletion'  THEN "pct" END),0) AS "HomoDel_pct",
    COALESCE(MAX(CASE WHEN "cnv_type" = 'Heterozygous Deletion' THEN "pct" END),0) AS "HetDel_pct",
    COALESCE(MAX(CASE WHEN "cnv_type" = 'Diploid'              THEN "pct" END),0) AS "Diploid_pct",
    COALESCE(MAX(CASE WHEN "cnv_type" = 'Gain'                 THEN "pct" END),0) AS "Gain_pct",
    COALESCE(MAX(CASE WHEN "cnv_type" = 'Amplification'        THEN "pct" END),0) AS "Amp_pct"
FROM freq
GROUP BY "band","band_start","band_end"
ORDER BY TRY_TO_NUMBER("band") NULLS LAST;   -- numeric chr order, X/Y last