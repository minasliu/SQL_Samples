SET LINESIZE 350;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET VERIFY OFF;
/*****************************************************************************/
/*     File Name     : MixCheckQuery.sql                                  */
/*     Description   : Pulls Mix consumption for MixCheck Report	*/
/*     Input tables  : Sunpar_Kc_Desc_Summary, Sunpar_cr_Summary           */
/*     Output file   : /home/minal/HardDrives/Reporting/MixCheckData.txt*/
/*****************************************************************************/

VARIABLE currqtr CHAR(6);

BEGIN
    SELECT fiscal_year_qtr
    INTO   :currqtr
    FROM   date_cd_v
    WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY');
  END;
/

SELECT TO_CHAR(sysdate,'Mon DD YYYY HH:MIAM') FROM dual;

CREATE TABLE MixTempData AS
SELECT	changed_date,
	Fiscal_Qtr,
	platform_category PLAT_CAT,
	platform PLAT,
	KC_DESC,
	sum(plan_qty) KC_PLAN,
	sum(PLAN_MIX) KC_PLAN_MIX
FROM 	Sunpar_Kc_Desc_Summary 
WHERE 	Kc_type IN ('STORAGE_HD') 
AND 	Kc_Cat IN ('3.5" DISK')
AND	rev_flag='B'
AND 	fiscal_qtr=
		(SELECT fiscal_year_qtr
		FROM date_cd_v
		WHERE TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY'))
GROUP BY changed_date,
	Fiscal_Qtr, 
	platform_category,
	platform,
	kc_desc
ORDER BY Fiscal_Qtr,
	platform_category,
	platform,
	kc_desc,
	changed_date
;

CREATE TABLE KCTempData AS
SELECT	platform_name PLAT,
	KC_DESC,
	sum(bklgcrdcurr) KC_BLOG,
	sum(Ship_Qty) KC_SHIPS
FROM 	kc_qtr_data_v 
WHERE 	Kc_type IN ('STORAGE_HD') 
AND 	Kc_cat IN ('3.5" DISK')
AND	prod_no!=('R*')
AND 	fiscal_qtr=
		(SELECT fiscal_year_qtr
		FROM date_cd_v
		WHERE TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY'))
GROUP BY platform_name,
	kc_desc;

CREATE TABLE PlatTempData AS
SELECT 	changed_date,
	Fiscal_Qtr,
	platform_category PLAT_CAT,
	platform PLAT,
	sum(requested_supply) PLAT_PLAN,
	sum(gross_ship_qty) PLAT_SHIPS,
	sum(TOTAL_CRD_Backlog) PLAT_BLOG
FROM	sunpar_cr_summary
WHERE	rev_flag='B'
AND 	fiscal_qtr=
		(SELECT fiscal_year_qtr
		FROM date_cd_v
		WHERE TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY'))
GROUP BY changed_date,
	Fiscal_Qtr,
	platform,
	platform_category
;
SPOOL /home/minal/HardDrives/Reporting/MixCheckData.txt
PROMPT PlatCat|Plat|KCDesc|KCPlan|KCPlanMix|KCBlog|KCShips|PlatPlan|PlatShips|PlatBlog|
SELECT DISTINCT
	a.PLAT_CAT || '|' ||
	a.PLAT || '|' ||
	a.KC_DESC || '|' ||
	sum(a.KC_PLAN) || '|' ||
	sum(a.KC_PLAN_MIX) || '|' ||
	sum(c.KC_BLOG) || '|' ||
	sum(c.KC_SHIPS) || '|' ||
	sum(b.PLAT_PLAN) || '|' ||
	sum(b.PLAT_SHIPS) || '|' ||
	sum(b.PLAT_BLOG) || '|'
FROM 	MixTempData a,
	PlatTempData b,
	KCTempData c
WHERE	a.PLAT_CAT=b.PLAT_CAT
AND	a.PLAT=b.PLAT
AND	a.PLAT=c.PLAT
AND	a.kc_desc=c.kc_desc
AND	a.fiscal_qtr=b.fiscal_qtr
AND	a.fiscal_qtr=:currqtr
AND	a.changed_date=
		(SELECT MAX(changed_date)
		FROM MixTempData)
AND	b.changed_date=
		(SELECT MAX(changed_date)
		FROM PlatTempData)
GROUP BY a.PLAT_CAT,
	a.PLAT,
	a.KC_DESC
;

SPOOL OFF;

COMMIT;
DROP TABLE MixTempData;
DROP TABLE PlatTempData;
DROP TABLE KCTempData;
exit;