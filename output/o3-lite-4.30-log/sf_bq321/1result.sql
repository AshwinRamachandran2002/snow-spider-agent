WITH
dwi AS (
    SELECT DISTINCT "StudyInstanceUID" AS uid
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "SeriesDescription" ILIKE '%DWI%'
),
t2_axial AS (
    SELECT DISTINCT "StudyInstanceUID" AS uid
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "SeriesDescription" ILIKE '%T2%Weighted%Axial%'
),
adc AS (
    SELECT DISTINCT "StudyInstanceUID" AS uid
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "SeriesDescription" ILIKE '%Apparent%Diffusion%Coefficient%'
),
t2_axial_seg AS (
    SELECT DISTINCT s."StudyInstanceUID" AS uid
    FROM IDC.IDC_V17.SEGMENTATIONS s
    JOIN IDC.IDC_V17.DICOM_PIVOT p
      ON p."SeriesInstanceUID" = s."segmented_SeriesInstanceUID"
    WHERE p."collection_id" = 'qin_prostate_repeatability'
      AND p."SeriesDescription" ILIKE '%T2%Weighted%Axial%'
),
all_uids AS (
    SELECT uid FROM dwi
    UNION
    SELECT uid FROM t2_axial
    UNION
    SELECT uid FROM adc
    UNION
    SELECT uid FROM t2_axial_seg
)
SELECT
    'all_four_categories' AS series_type,
    COUNT(*)              AS unique_studyinstanceuids
FROM all_uids;