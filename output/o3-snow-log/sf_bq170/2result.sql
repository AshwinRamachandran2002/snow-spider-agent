/*---------------------------------------------------------------------------
  Copy-number variation (CNV) frequencies for all cytobands in
  TCGA-BRCA cases – GDC Release 23 (allelic segments, hg38).
---------------------------------------------------------------------------*/
WITH brca_segments AS (               /* 1.  TCGA-BRCA allelic segments */
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

cytobands AS (                        /* 2.  hg38 cytoband coordinates  */
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

overlapping AS (                      /* 3.  segment ↔ cytoband overlap */
    SELECT
        s."case_barcode",
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        /* overlap length (bp) */
        LEAST(c."hg38_stop", s."end_pos")
          - GREATEST(c."hg38_start", s."start_pos")          AS overlap_len,
        s."copy_number"
    FROM brca_segments  s
    JOIN cytobands      c
      ON REPLACE(s."chromosome",'chr','') = REPLACE(c."chromosome",'chr','')
     AND LEAST(c."hg38_stop", s."end_pos")
         > GREATEST(c."hg38_start", s."start_pos")           /* real overlap */
),

band_case_cn AS (                     /* 4.  weighted CN per band/case  */
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        ROUND(
              SUM(overlap_len * "copy_number")
              / NULLIF(SUM(overlap_len),0)
        )                                                AS rounded_cn
    FROM overlapping
    GROUP BY 1,2,3,4
),

band_case_class AS (                  /* 5.  classify rounded CN        */
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        rounded_cn,
        CASE
            WHEN rounded_cn = 0 THEN 'Homozygous_Del'
            WHEN rounded_cn = 1 THEN 'Heterozygous_Del'
            WHEN rounded_cn = 2 THEN 'Diploid'
            WHEN rounded_cn = 3 THEN 'Gain'
            WHEN rounded_cn > 3 THEN 'Amplification'
        END                                           AS cnv_type
    FROM band_case_cn
),

total_cases AS (                      /* 6.  total TCGA-BRCA cases      */
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM brca_segments
),

band_frequencies AS (                 /* 7.  % frequency of each CNV    */
    SELECT
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        ROUND(
              SUM(IFF(b.cnv_type = 'Homozygous_Del', 1, 0))
              * 100.0 / n.n_cases , 2)                 AS pct_homozygous_deletions,
        ROUND(
              SUM(IFF(b.cnv_type = 'Heterozygous_Del', 1, 0))
              * 100.0 / n.n_cases , 2)                 AS pct_heterozygous_deletions,
        ROUND(
              SUM(IFF(b.cnv_type = 'Diploid', 1, 0))
              * 100.0 / n.n_cases , 2)                 AS pct_diploid,
        ROUND(
              SUM(IFF(b.cnv_type = 'Gain', 1, 0))
              * 100.0 / n.n_cases , 2)                 AS pct_gains,
        ROUND(
              SUM(IFF(b.cnv_type = 'Amplification', 1, 0))
              * 100.0 / n.n_cases , 2)                 AS pct_amplifications
    FROM band_case_class b
    CROSS JOIN total_cases n
    GROUP BY
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        n.n_cases
)

SELECT *
FROM band_frequencies
ORDER BY "cytoband_name" NULLS LAST;