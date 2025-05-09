WITH
/* ------------------------------------------------------------------ *
 * 1. Cytoband coordinates (hg38)                                     *
 * ------------------------------------------------------------------ */
cytoband AS (
    SELECT  "chromosome"          AS chr,
            "cytoband_name"       AS band,
            "hg38_start"          AS band_start,
            "hg38_stop"           AS band_stop
    FROM    TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),
/* ------------------------------------------------------------------ *
 * 2. Copy‑number segments – Release 23, TCGA‑BRCA only               *
 * ------------------------------------------------------------------ */
segments AS (
    SELECT  "case_barcode",
            "chromosome"          AS chr,
            "start_pos",
            "end_pos",
            "copy_number"                 -- already integer
    FROM    TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE   "project_short_name" = 'TCGA-BRCA'
),
/* ------------------------------------------------------------------ *
 * 3. Total number of BRCA cases (scalar)                             *
 * ------------------------------------------------------------------ */
brca_case_cnt AS (
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases FROM segments
),
/* ------------------------------------------------------------------ *
 * 4. Overlap of each segment with each cytoband                      *
 * ------------------------------------------------------------------ */
seg_band_overlap AS (
    SELECT  s."case_barcode",
            c.band,
            c.band_start,
            c.band_stop,
            LEAST(s."end_pos",  c.band_stop)
              - GREATEST(s."start_pos", c.band_start)   AS ov_len,
            s."copy_number"
    FROM    segments s
    JOIN    cytoband c
           ON s.chr = c.chr
          AND s."end_pos"   >  c.band_start   -- positive overlap
          AND s."start_pos" <  c.band_stop
),
/* ------------------------------------------------------------------ *
 * 5. Weighted average copy number per case × cytoband                *
 * ------------------------------------------------------------------ */
case_band_cn AS (
    SELECT  "case_barcode",
            band,
            band_start,
            band_stop,
            ROUND( SUM(ov_len * "copy_number") / SUM(ov_len), 0 ) AS cn_rounded
    FROM    seg_band_overlap
    GROUP BY
            "case_barcode", band, band_start, band_stop
),
/* ------------------------------------------------------------------ *
 * 6. Map rounded copy number to CNV category                         *
 * ------------------------------------------------------------------ */
case_band_type AS (
    SELECT  *,
            CASE cn_rounded
                 WHEN 0 THEN 'Homozygous Deletion'
                 WHEN 1 THEN 'Heterozygous Deletion'
                 WHEN 2 THEN 'Diploid'
                 WHEN 3 THEN 'Gain'
                 WHEN 4 THEN 'Amplification'
                 ELSE 'Amplification'          -- >4 copies
            END AS cnv_type
    FROM    case_band_cn
)
/* ------------------------------------------------------------------ *
 * 7. Frequency of each CNV type per cytoband                         *
 * ------------------------------------------------------------------ */
SELECT
        band                          AS "CYTOBAND",
        band_start                    AS "BAND_START",
        band_stop                     AS "BAND_STOP",
        ROUND( 100.0 * SUM( IFF(cnv_type = 'Homozygous Deletion'  ,1,0) )
               / MAX(bc.n_cases) , 2) AS "HOMOZYGOUS_DEL_%",
        ROUND( 100.0 * SUM( IFF(cnv_type = 'Heterozygous Deletion',1,0) )
               / MAX(bc.n_cases) , 2) AS "HETEROZYGOUS_DEL_%",
        ROUND( 100.0 * SUM( IFF(cnv_type = 'Diploid'              ,1,0) )
               / MAX(bc.n_cases) , 2) AS "DIPLOID_%",
        ROUND( 100.0 * SUM( IFF(cnv_type = 'Gain'                 ,1,0) )
               / MAX(bc.n_cases) , 2) AS "GAIN_%",
        ROUND( 100.0 * SUM( IFF(cnv_type = 'Amplification'        ,1,0) )
               / MAX(bc.n_cases) , 2) AS "AMPLIFICATION_%"
FROM        case_band_type cb
CROSS JOIN  brca_case_cnt  bc          -- supplies scalar n_cases
GROUP BY    band, band_start, band_stop
ORDER BY    band
;