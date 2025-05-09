SELECT DISTINCT MR."StudyInstanceUID"
FROM
(
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17."DICOM_PIVOT"
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%t2 weighted axial%'
) MR
JOIN
(
    SELECT DISTINCT s."StudyInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS" s
    JOIN IDC.IDC_V17."DICOM_PIVOT" dp_seg ON s."SeriesInstanceUID" = dp_seg."SeriesInstanceUID"
    WHERE dp_seg."collection_id" = 'qin_prostate_repeatability'
      AND dp_seg."Modality" = 'SEG'
      AND s."SegmentedPropertyType"::VARIANT:"CodeMeaning"::STRING ILIKE '%peripheral zone%'
) SEG ON MR."StudyInstanceUID" = SEG."StudyInstanceUID";