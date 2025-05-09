/* ------------------------------------------------------------
   Cytoband‑level CNV frequency profile for TCGA‑BRCA
   ------------------------------------------------------------ */
WITH brca_seg AS (  -- TCGA‑BRCA copy‑number segments
    SELECT *
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."COPY_NUMBER_SEGMENT_MASKED"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
case_cnt AS (       -- number of unique BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM brca_seg
),
/* hg38 cytoband table (approximate p/q‑arm breaks used here) */
cyto AS (
    SELECT *
    FROM VALUES
      ('1p',  '1',  1,        123000000),
      ('1q',  '1',  123000001,248956422),
      ('2p',  '2',  1,         92000000),
      ('2q',  '2',  92000001, 242193529),
      ('3p',  '3',  1,         91000000),
      ('3q',  '3',  91000001, 198295559),
      ('4p',  '4',  1,         50000000),
      ('4q',  '4',  50000001, 190214555),
      ('5p',  '5',  1,         49000000),
      ('5q',  '5',  49000001, 181538259),
      ('6p',  '6',  1,         60000000),
      ('6q',  '6',  60000001, 170805979),
      ('7p',  '7',  1,         61000000),
      ('7q',  '7',  61000001, 159345973),
      ('8p',  '8',  1,         46000000),
      ('8q',  '8',  46000001, 145138636),
      ('9p',  '9',  1,         45000000),
      ('9q',  '9',  45000001, 138394717),
      ('10p', '10', 1,         40000000),
      ('10q', '10', 40000001, 133797422),
      ('11p', '11', 1,         53000000),
      ('11q', '11', 53000001, 135086622),
      ('12p', '12', 1,         34000000),
      ('12q', '12', 34000001, 133275309),
      ('13p', '13', 1,         17000000),
      ('13q', '13', 17000001, 114364328),
      ('14p', '14', 1,         17000000),
      ('14q', '14', 17000001, 107043718),
      ('15p', '15', 1,         19000000),
      ('15q', '15', 19000001, 101991189),
      ('16p', '16', 1,         36000000),
      ('16q', '16', 36000001,  90338345),
      ('17p', '17', 1,         22000000),
      ('17q', '17', 22000001,  83257441),
      ('18p', '18', 1,         17000000),
      ('18q', '18', 17000001,  80373285),
      ('19p', '19', 1,         27000000),
      ('19q', '19', 27000001,  58617616),
      ('20p', '20', 1,         27000000),
      ('20q', '20', 27000001,  64444167),
      ('21p', '21', 1,         11000000),
      ('21q', '21', 11000001,  46709983),
      ('22p', '22', 1,         12000000),
      ('22q', '22', 12000001,  50818468),
      ('Xp',  'X',  1,         60000000),
      ('Xq',  'X',  60000001, 156040895)
    AS t(cytoband, chr_num, start_pos, end_pos)
),
/* length‑weighted mean log2 ratio per case & cytoband */
band_case AS (
    SELECT
        c.cytoband,
        c.start_pos,
        c.end_pos,
        s."case_barcode",
        SUM( (LEAST(s."end_pos", c.end_pos) - GREATEST(s."start_pos", c.start_pos) + 1)
             * s."segment_mean" )
        /
        SUM( LEAST(s."end_pos", c.end_pos) - GREATEST(s."start_pos", c.start_pos) + 1 )
        AS wmean_log2
    FROM brca_seg s
    JOIN cyto     c
      ON c.chr_num = s."chromosome"
     AND s."end_pos"   >= c.start_pos
     AND s."start_pos" <= c.end_pos
    GROUP BY c.cytoband, c.start_pos, c.end_pos, s."case_barcode"
),
/* rounded copy‑number & CNV class */
band_case_class AS (
    SELECT
        cytoband,
        start_pos,
        end_pos,
        "case_barcode",
        ROUND(2 * POWER(2, wmean_log2)) AS rounded_cn,
        CASE
            WHEN ROUND(2 * POWER(2, wmean_log2)) = 0 THEN 'homozygous_deletion'
            WHEN ROUND(2 * POWER(2, wmean_log2)) = 1 THEN 'heterozygous_deletion'
            WHEN ROUND(2 * POWER(2, wmean_log2)) = 2 THEN 'normal'
            WHEN ROUND(2 * POWER(2, wmean_log2)) = 3 THEN 'gain'
            WHEN ROUND(2 * POWER(2, wmean_log2))  > 3 THEN 'amplification'
        END AS cnv_class
    FROM band_case
),
/* frequency of CNV classes across all cases */
band_freq AS (
    SELECT
        cytoband,
        start_pos,
        end_pos,
        ROUND(100.0 * COUNT_IF(cnv_class = 'homozygous_deletion')   / cc.n_cases, 2) AS homozygous_deletion_pct,
        ROUND(100.0 * COUNT_IF(cnv_class = 'heterozygous_deletion') / cc.n_cases, 2) AS heterozygous_deletion_pct,
        ROUND(100.0 * COUNT_IF(cnv_class = 'normal')                / cc.n_cases, 2) AS normal_pct,
        ROUND(100.0 * COUNT_IF(cnv_class = 'gain')                  / cc.n_cases, 2) AS gain_pct,
        ROUND(100.0 * COUNT_IF(cnv_class = 'amplification')         / cc.n_cases, 2) AS amplification_pct
    FROM band_case_class, case_cnt cc
    GROUP BY cytoband, start_pos, end_pos, cc.n_cases
)
/* final result ------------------------------------------------ */
SELECT
    cytoband,
    start_pos AS "start",
    end_pos   AS "end",
    homozygous_deletion_pct,
    heterozygous_deletion_pct,
    normal_pct,
    gain_pct,
    amplification_pct
FROM band_freq
ORDER BY cytoband;