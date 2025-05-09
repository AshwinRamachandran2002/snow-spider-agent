/*---------------------------------------------------------------------------
  Breast‑cancer (TCGA‑BRCA) copy‑number profile per cytoband (GDC Release 23)
---------------------------------------------------------------------------*/
WITH cytobands AS (               -- hg38 cytoband co‑ordinates
    SELECT
        "chromosome"   AS chromosome,
        "hg38_start"   AS hg38_start,
        "hg38_stop"    AS hg38_stop,
        "cytoband_name" AS cytoband_name
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

brca_segments AS (                -- copy‑number segments for BRCA (release‑23)
    SELECT
        "chromosome"   AS chromosome,
        "start_pos"    AS start_pos,
        "end_pos"      AS end_pos,
        "copy_number"  AS seg_copy_num,
        "case_barcode" AS case_barcode
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

band_segment_overlap AS (         -- overlap length between each band/segment
    SELECT
        b.cytoband_name,
        b.hg38_start,
        b.hg38_stop,
        s.case_barcode,
        GREATEST(
            0,
            LEAST(b.hg38_stop, s.end_pos)
            - GREATEST(b.hg38_start, s.start_pos) + 1
        )                        AS overlap_len,
        s.seg_copy_num
    FROM cytobands      b
    JOIN brca_segments  s
      ON b.chromosome = s.chromosome
     AND s.start_pos  <= b.hg38_stop
     AND s.end_pos    >= b.hg38_start
),

weighted_cnv AS (                 -- overlap‑weighted copy number per band/case
    SELECT
        cytoband_name,
        hg38_start,
        hg38_stop,
        case_barcode,
        ROUND(
            SUM(overlap_len * seg_copy_num)
            / NULLIF(SUM(overlap_len),0)
        )                        AS cn_rounded
    FROM band_segment_overlap
    GROUP BY cytoband_name, hg38_start, hg38_stop, case_barcode
),

classified AS (                   -- map rounded copy number → CNV category
    SELECT
        cytoband_name,
        hg38_start,
        hg38_stop,
        case_barcode,
        CASE
            WHEN cn_rounded = 0 THEN 'HOMO_DEL'
            WHEN cn_rounded = 1 THEN 'HET_DEL'
            WHEN cn_rounded = 2 THEN 'DIPLOID'
            WHEN cn_rounded = 3 THEN 'GAIN'
            WHEN cn_rounded > 3 THEN 'AMPLIFICATION'
        END                      AS cnv_type
    FROM weighted_cnv
)

SELECT
    cytoband_name,
    hg38_start,
    hg38_stop,
    ROUND(100 * SUM(IFF(cnv_type = 'HOMO_DEL',      1, 0))
              / COUNT(DISTINCT case_barcode), 2) AS pct_homo_del,
    ROUND(100 * SUM(IFF(cnv_type = 'HET_DEL',       1, 0))
              / COUNT(DISTINCT case_barcode), 2) AS pct_hetero_del,
    ROUND(100 * SUM(IFF(cnv_type = 'DIPLOID',       1, 0))
              / COUNT(DISTINCT case_barcode), 2) AS pct_diploid,
    ROUND(100 * SUM(IFF(cnv_type = 'GAIN',          1, 0))
              / COUNT(DISTINCT case_barcode), 2) AS pct_gain,
    ROUND(100 * SUM(IFF(cnv_type = 'AMPLIFICATION', 1, 0))
              / COUNT(DISTINCT case_barcode), 2) AS pct_amplification
FROM classified
GROUP BY cytoband_name, hg38_start, hg38_stop
ORDER BY cytoband_name;