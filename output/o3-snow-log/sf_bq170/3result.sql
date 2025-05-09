/* ------------------------------------------------------------------
   Copy-number landscape (HG38) for TCGA-BRCA – GDC Release 23
   ------------------------------------------------------------------ */
WITH brca_seg AS (                 /* Allelic segments for TCGA-BRCA */
    SELECT
        "case_barcode"                       AS case_id,
        "chromosome"                         AS chr,        /* e.g. chr1 */
        "start_pos"                          AS seg_start,
        "end_pos"                            AS seg_end,
        "copy_number"                        AS copy_number
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

bands AS (                        /* Cytoband coordinates (HG38)     */
    SELECT
        "cytoband_name"                    AS CYTOBAND_NAME,
        "chromosome"                       AS chr,
        "hg38_start"                       AS band_start,
        "hg38_stop"                        AS band_end
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

overlap_raw AS (                  /* Segment × band intersection     */
    SELECT
        s.case_id,
        b.CYTOBAND_NAME,
        b.band_start,
        b.band_end,
        /* length of genomic overlap (≥0) */
        GREATEST(
            0,
            LEAST(s.seg_end , b.band_end ) - GREATEST(s.seg_start , b.band_start)
        )                                        AS ov_len,
        s.copy_number
    FROM brca_seg  s
    JOIN bands     b
      ON b.chr = s.chr
    WHERE GREATEST(
              0,
              LEAST(s.seg_end , b.band_end ) - GREATEST(s.seg_start , b.band_start)
          ) > 0
),

band_case_cn AS (                 /* Weighted CN per case × band     */
    SELECT
        case_id,
        CYTOBAND_NAME,
        band_start,
        band_end,
        ROUND(                                   /* nearest integer  */
            SUM(ov_len * copy_number) / NULLIF(SUM(ov_len), 0)
        )                                        AS rounded_cn
    FROM overlap_raw
    GROUP BY
        case_id, CYTOBAND_NAME, band_start, band_end
),

band_case_class AS (              /* Map rounded CN to CNV category  */
    SELECT
        CYTOBAND_NAME,
        band_start,
        band_end,
        case_id,
        CASE
            WHEN rounded_cn = 0 THEN 'Homozygous Deletion'
            WHEN rounded_cn = 1 THEN 'Heterozygous Deletion'
            WHEN rounded_cn = 2 THEN 'Diploid'
            WHEN rounded_cn = 3 THEN 'Gain'
            WHEN rounded_cn > 3 THEN 'Amplification'
            ELSE 'Unknown'
        END                                   AS cnv_type
    FROM band_case_cn
),

tot_cases AS (                    /* Total number of TCGA-BRCA cases */
    SELECT COUNT(DISTINCT case_id) AS n_cases
    FROM brca_seg
),

band_freq AS (                    /* % frequency of each CNV type    */
    SELECT
        c.CYTOBAND_NAME,
        MIN(c.band_start)                       AS hg38_start,
        MIN(c.band_end)                         AS hg38_end,

        100.0 * SUM(CASE WHEN cnv_type = 'Homozygous Deletion'   THEN 1 ELSE 0 END)
              / n.n_cases                       AS pct_homdel,

        100.0 * SUM(CASE WHEN cnv_type = 'Heterozygous Deletion' THEN 1 ELSE 0 END)
              / n.n_cases                       AS pct_hetdel,

        100.0 * SUM(CASE WHEN cnv_type = 'Diploid'               THEN 1 ELSE 0 END)
              / n.n_cases                       AS pct_diploid,

        100.0 * SUM(CASE WHEN cnv_type = 'Gain'                  THEN 1 ELSE 0 END)
              / n.n_cases                       AS pct_gain,

        100.0 * SUM(CASE WHEN cnv_type = 'Amplification'         THEN 1 ELSE 0 END)
              / n.n_cases                       AS pct_amp
    FROM band_case_class c
    CROSS JOIN tot_cases  n
    GROUP BY
        c.CYTOBAND_NAME, n.n_cases
)

SELECT
    CYTOBAND_NAME                               AS cytoband_name,
    hg38_start,
    hg38_end,
    ROUND(pct_homdel , 2)  AS pct_homozygous_deletion,
    ROUND(pct_hetdel , 2)  AS pct_heterozygous_deletion,
    ROUND(pct_diploid, 2)  AS pct_diploid,
    ROUND(pct_gain   , 2)  AS pct_gain,
    ROUND(pct_amp    , 2)  AS pct_amplification
FROM band_freq
ORDER BY CYTOBAND_NAME;