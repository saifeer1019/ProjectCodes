

/* Setting empty property addressess. In some cases the property address is the same for the same
 parcelID so I could use it to get the address without difficulty. I had to be careful not 
 to mix it up with the uniqueID since that would give me the same rows in the self join. */

select * from nashville where propertyaddress = '';
SELECT * FROM NASHVILLE A join nashville B on  A.ParcelID = B.ParcelID AND B.ï»¿UniqueID <> A.ï»¿UniqueID;
UPDATE nashville A JOIN nashville B 
ON A.ParcelID = B.ParcelID AND B.ï»¿UniqueID <> A.ï»¿UniqueID 
SET A.propertyaddress = CASE WHEN A.propertyaddress = '' THEN B.propertyaddress ELSE A.propertyaddress END;


/* I then use substrings to get the city and area out of the address*/


SELECT propertyaddress,
substring(propertyaddress, 1, LOCATE(',', propertyaddress)-1) as Address, 
substring(propertyaddress, LOCATE(',', propertyaddress) + 1, length(propertyaddress)) as City, 
TRIM(substring(propertyaddress, LOCATE(' ', propertyaddress) + 1 ,LOCATE(',', propertyaddress) - LOCATE(' ', propertyaddress) - 1)) as area 
FROM nashville;

alter table nashville 
add City text;
alter table nashville 
add Area text;
update nashville set City = substring(propertyaddress, LOCATE(',', propertyaddress) + 1, length(propertyaddress));
update nashville set Area = TRIM(substring(propertyaddress, LOCATE(' ', propertyaddress) + 1 ,LOCATE(',', propertyaddress) - LOCATE(' ', propertyaddress) - 1));

/* I get the owner address info using substring index. */
select  TRIM(substring(owneraddress, LOCATE(' ', owneraddress) + 1 ,LOCATE(',', owneraddress) - LOCATE(' ', owneraddress) - 1)), 
		substring_index(substring_index(owneraddress,',', 2), ',', -1), 
		substring_index(substring_index(owneraddress,',', 3), ',', -1)
 from nashville;

alter table nashville 
add Owner_City text;
alter table nashville 
add Owner_Area text;
alter table nashville 
add Owner_State text;

update nashville set Owner_City = substring(owneraddress, LOCATE(',', owneraddress) + 1, length(owneraddress));
update nashville set Owner_Area = TRIM(substring(owneraddress, LOCATE(' ', owneraddress) + 1 ,LOCATE(',', owneraddress) - LOCATE(' ', owneraddress) - 1));
update nashville set Owner_State = substring_index(substring_index(owneraddress,',', 3), ',', -1);


/* Some additional fixes */
SELECT SOLDASVACANT, count(soldasvacant) FROM nashville group by SoldAsVacant


update nashville
set soldasvacant = case when soldasvacant='N' 
						THEN 'No' 
                        when soldasvacant='Y' 
                        Then 'Yes'  
                        else soldasvacant 
                        end;



/* Using row Number to get rid of duplicates*/

create table nashville_without_duplicates 
(select * from nashville 
where ï»¿UniqueID not in
 (with nashville_cte as
 (select *, row_number() over (partition by ParcelID, SalePrice, LegalReference ) as rownumCTH
 from nashville)       /* When I run the row Number I find quite a lot of entries where the LegalReference,SalePrice and PacelID are all the same so they are resundant */
; 
 
 rename table nashville to nashville_old;
 rename table nashville_without_duplicates to nashville
 

/*adding different new values to use later and find insights*/
alter table nashville
add column per_acre_value float;
update nashville
set per_acre_value = LandValue  / Acreage;
update nashville  
set OwnerAddress = substring(OwnerAddress, 1 , length(OwnerAddress) - 4);
alter table nashville
add column building_no text;
update nashville
set building_no = SUBSTRING(PROPERTYADDRESS, 1, LOCATE(' ', PROPERTYADDRESS) -1);




/* Now to find insights */

/* Lookit at overall numbers of each city. */

select CITY,  round(AVG(saleprice), 2) AS Averege_Price, 
round(AVG(acreage), 2) AS Averege_Price, round(AVG(landvalue), 2) AS Average_landvalue,
 round(AVG(per_acre_value), 2) AS average_land_value_per_acre,
 round(AVG(Bedrooms), 2) AS average_Bedrooms, round(AVG(FullBath), 2) AS average_FullBath
from nashville 
GROUP BY CITY;


/* Lookit at overall numbers of each tax district. */

select taxdistrict,  round(AVG(saleprice), 2) AS Averege_Price, 
round(AVG(acreage), 2) AS Averege_Price, round(AVG(landvalue), 2) AS Average_landvalue,
 round(AVG(per_acre_value), 2) AS average_land_value_per_acre,
 round(AVG(Bedrooms), 2) AS average_Bedrooms, round(AVG(FullBath), 2) AS average_FullBath
from nashville 
GROUP BY taxdistrict;


/* Areas with the highest average land price*/
create view  expensive_land_areas as(
SELECT City, AREA,  AVG(per_acre_value) AS Land_Price_Average 
FROM nashville
GROUP BY AREA, City ORDER BY Land_Price_Average DESC
LIMIT 10);

/* Areas with the cheapest average land price*/
create view  cheap_land_areas as 
(SELECT City, AREA, AVG(per_acre_value) as Land_Price_Average 
FROM nashville  WHERE landuse = 'SINGLE FAMILY'
GROUP BY AREA, City ORDER BY Land_Price_Average ASC
LIMIT 10);



/* Cities with the highest average land price*/
create view  expensive_land_cities as(
SELECT AVG(per_acre_value) AS Land_Price_Average, City 
FROM nashville 
GROUP BY City ORDER BY Land_Price_Average DESC
LIMIT 10);

/* Cities with the cheapest average land price*/
create view  cheap_land_cities as
 (SELECT City, AVG(per_acre_value) as Land_Price_Average 
 FROM nashville  WHERE landuse = 'SINGLE FAMILY'
 GROUP BY  City ORDER BY Land_Price_Average ASC
 LIMIT 10);
 


/*Getting the number of each type of land sold*/

select count(*), landuse 
from nashville 
group by landuse order by count(*) desc;



/*Areas with the most lands in a certain time span. I had to index the CTE's to properly join them.*/ 
WITH CTE_A 	 as
	(SELECT AREA AS `19th_century`,
		count(CASE WHEN yearbuilt  between 1798 and 1900 THEN 1 END) AS Buildings_
        from nashville GROUP BY  AREA order by Buildings_ desc limit 10),

        
 CTE_B 	 as
	(SELECT AREA AS `20th_century`, 
		count(CASE WHEN yearbuilt  between 1900 and 2000 THEN 1 END) AS Buildings_
        from nashville GROUP BY  AREA order by Buildings_ desc limit 10),

 CTE_C 	 as	
	(SELECT AREA AS `21st_century`, 
		count(CASE WHEN yearbuilt  > 2000 THEN 1 END) AS Buildings_ 
        from nashville GROUP BY  AREA order by Buildings_ desc limit 10),

 A_idxd  as
	(SELECT Buildings_, 
		`19th_century`, ROW_NUMBER() OVER (ORDER BY Buildings_ DESC) as Buildings
        from CTE_A ),
 B_idxd   as
	(SELECT Buildings_, 
		`20th_century`, ROW_NUMBER() OVER (ORDER BY Buildings_ DESC) as Buildings
        from CTE_B ),
 C_idxd   as
	(SELECT Buildings_,
		`21st_century`, ROW_NUMBER() OVER (ORDER BY Buildings_ DESC) as Buildings
        from CTE_C )
        

 SELECT `19th_century`, A_idxd.Buildings_, `20th_century`, B_idxd.Buildings_, `21st_century`, C_idxd.Buildings_  FROM A_idxd 
 JOIN B_idxd ON A_idxd.Buildings = B_idxd.Buildings
  JOIN C_idxd ON B_idxd.Buildings = C_idxd.Buildings;
	

/* Top 10 profitable Companies*/

ALTER table nashville 
ADD COLUMN Profit int;

UPDATE nashville
 SET Profit = SalePrice - TotalValue ;

SELECT OwnerName, AVG(Profit), MAX(Profit), MIN( Profit) 
 FROM nashville
 GROUP BY OwnerName ORDER BY AVG(Profit) DESC LIMIT 10;



/* 			*/

WITH Prices_Optimum as (
SELECT Area, City, count(*) AS Properties_Sold, AVG(SALEPRICE) AS `AVG_Price`
 FROM nashville
 WHERE acreage between 0.2 and 0.5
 AND LANDUSE = 'SINGLE FAMILY' AND 
 Bedrooms between 2 and 5
 GROUP BY CITY, AREA 
 ORDER BY count(*) DESC
 )
 
SELECT Area, City, Properties_Sold, AVG_Price 
FROM Prices_Optimum
WHERE Properties_Sold > 10
ORDER BY AVG_Price 
;




/*Looking at large lands with duplex or higher or more*/
WITH Prices_Optimum as (
SELECT Area, City, count(*) AS Properties_Sold, AVG(SALEPRICE) AS `AVG_Price`
 FROM nashville
 WHERE acreage between 0.5 and 2 AND LANDUSE = 'DUPLEX'
 GROUP BY CITY, AREA ORDER BY count(*) DESC
 LIMIT 10
 )
 
SELECT Area, City, Properties_Sold, AVG_Price 
FROM Prices_Optimum 
ORDER BY AVG_Price
 ;



/* Building values of different years for the average home*/

select YearBuilt, AVG(BuildingValue) 
from nashville
where soldasvacant = 'no'and bedrooms = 3 and fullbath between 2 and 5 
group by yearbuilt
order by AVG(BuildingValue) asc













