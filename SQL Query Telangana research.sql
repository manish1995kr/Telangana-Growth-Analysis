Stamp Registration
1. How does the revenue generated from document registration vary across districts in Telangana? List down the top 5 districts that showed 
the highest document registration revenue growth between FY 2019 and 2022.

select * from fact_stamps;
ALTER TABLE fact_stamps
ADD fiscal_year VARCHAR(10);
-- Update the new column with the extracted year from the date_column
UPDATE fact_stamps
SET fiscal_year = 
    CASE 
        WHEN MONTH(month) >= 4 THEN YEAR(month)
        ELSE YEAR(month) - 1
    END;

SELECT district, sum(documents_registered_rev) AS revenue_growth FROM fact_stamps join dim_districts on 
dim_districts.dist_code = fact_stamps.dist_code WHERE fiscal_year >= 2019 AND fiscal_year <= 2022 GROUP BY district ORDER BY 
revenue_growth DESC LIMIT 5;

2. How does the revenue generated from document registration compare to the revenue generated from e-stamp challans across districts? List 
down the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022?

SELECT district, sum(documents_registered_rev) as registration_rev, sum(estamps_challans_rev) as stamp_rev FROM fact_stamps 
join dim_districts on dim_districts.dist_code = fact_stamps.dist_code WHERE fiscal_year = 2022 and estamps_challans_rev > 
documents_registered_rev GROUP BY district ORDER BY stamp_rev DESC  LIMIT 5;

3. Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp 
challan? If so, what suggestions would you propose to the government?

SELECT fiscal_year, month(STR_TO_DATE(month, '%Y-%m-%d')) as months, sum(documents_registered_cnt), sum(estamps_challans_cnt) 
FROM fact_stamps GROUP BY fiscal_year, months;

4. Categorize districts into three segments based on their stamp registration revenue generation during the fiscal year 2021 to 2022.

SELECT district, SUM(estamps_challans_rev) AS total_revenue, NTILE(3) OVER (ORDER BY SUM(estamps_challans_rev) DESC) AS revenue_segment
FROM fact_stamps JOIN dim_districts ON dim_districts.dist_code = fact_stamps.dist_code WHERE fiscal_year >= 2021 AND fiscal_year <= 2022
GROUP BY district ORDER BY total_revenue DESC;

Transportation
5. Investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts. 
Are there any months or seasons that consistently show higher or lower sales rate, and if yes, what could be the driving factors? 
(Consider Fuel-Type category only)

select * from fact_transport;
ALTER TABLE fact_transport
ADD fiscal_year VARCHAR(10);
-- Update the new column with the extracted year from the date_column
UPDATE fact_transport
SET fiscal_year = 
    CASE 
        WHEN MONTH(month) >= 4 THEN YEAR(month)
        ELSE YEAR(month) - 1
    END;

SELECT district, quarter(STR_TO_DATE(month, '%Y-%m-%d')) as quarterly, sum(fuel_type_petrol) as petrol_sale, 
sum(fuel_type_diesel) as diesel_sale, sum(fuel_type_electric) as electric_sale, sum(fuel_type_others) as other_sale FROM fact_transport 
join dim_districts on dim_districts.dist_code = fact_transport.dist_code GROUP BY district, quarterly order by quarterly asc;

6. How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different 
districts? Are there any districts with a predominant preference for a specific vehicle class? Consider FY 2022 for analysis.

SELECT district, sum(vehicleClass_MotorCycle) as motorcycle, sum(vehicleClass_AutoRickshaw) as autorickshaw, sum(vehicleClass_MotorCar) as
motorcar, sum(vehicleClass_Agriculture) as agriculture FROM fact_transport join dim_districts on dim_districts.dist_code = 
fact_transport.dist_code where fiscal_year = 2022 GROUP BY district;

7. List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales growth during FY 2022 compared to FY 
2021? (Consider and compare categories: Petrol, Diesel and Electric)

WITH fy2021 AS (SELECT SUM(t.fuel_type_petrol + t.fuel_type_diesel + t.fuel_type_electric) as Total_Sales_2021, d.district as Districts,
EXTRACT(YEAR FROM t.month) as Year FROM fact_transport t JOIN dim_districts d USING (dist_code) WHERE EXTRACT(YEAR FROM t.month) = 2021
GROUP BY d.district, Year),

-- Create CTE for FY 2022
fy2022 AS (SELECT SUM(t.fuel_type_petrol + t.fuel_type_diesel + t.fuel_type_electric) as Total_Sales_2022, d.district as Districts,
EXTRACT(YEAR FROM t.month) as Year FROM fact_transport t JOIN dim_districts d USING (dist_code) WHERE EXTRACT(YEAR FROM t.month) = 2022
GROUP BY d.district, Year)

-- Main Query to Compare FY 2021 and FY 2022 Sales
SELECT fy2021.Districts, fy2021.Total_Sales_2021, fy2022.Total_Sales_2022,
ROUND(((fy2022.Total_Sales_2022 - fy2021.Total_Sales_2021) / fy2021.Total_Sales_2021) * 100, 2) AS Sales_Growth 
FROM fy2021 JOIN fy2022
ON fy2021.Districts = fy2022.Districts ORDER BY Sales_Growth desc LIMIT 3;

Ts-Ipass (Telangana State Industrial Project Approval and Self Certification System)
8. List down the top 5 sectors that have witnessed the most significant investments in FY 2022.

select * from fact_ts_ipass;
ALTER TABLE fact_ts_ipass
ADD fiscal_year VARCHAR(10);
-- Update the new column with the extracted year from the date_column
UPDATE fact_ts_ipass
SET fiscal_year = 
    CASE 
        WHEN MONTH(STR_TO_DATE(month, '%d/%m/%Y')) >= 4 THEN YEAR(STR_TO_DATE(month, '%d/%m/%Y'))
        ELSE YEAR(STR_TO_DATE(month, '%d/%m/%Y')) - 1
    END;
  
select sector, round(sum(investment_in_cr),2) as investment_in_Cr from fact_ts_ipass where fiscal_year = 2022 group by sector order by 
investment_in_cr desc limit 5;
 
9. List down the top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022? What factors could 
have led to the substantial investments in these particular districts?

SELECT district, sector,  round(sum(investment_in_cr),2) as Investment_in_Cr FROM fact_ts_ipass join dim_districts on 
dim_districts.dist_code = fact_ts_ipass.dist_code WHERE fiscal_year between 2019 and 2022 GROUP BY district ORDER BY 
Investment_in_cr DESC  LIMIT 3;

10. Is there any relationship between district investments, vehicles sales and stamps revenue within the same district between FY 2021
 and 2022?
 
SELECT dis.district, round(sum(inves.investment_in_cr),2) as investment, round(((sum(trans.vehicleClass_MotorCar + 
trans.vehicleClass_MotorCycle + trans.vehicleClass_AutoRickshaw + trans.vehicleClass_Agriculture + trans.vehicleClass_others))/10000000),2)
 as vehicle_rev, round(((sum(stamp.estamps_challans_rev))/10000000),2) as stamp_rev FROM fact_ts_ipass AS inves JOIN
fact_transport AS trans ON trans.dist_code = inves.dist_code AND trans.fiscal_year = inves.fiscal_year
JOIN
fact_stamps AS stamp ON inves.dist_code = stamp.dist_code AND inves.fiscal_year = stamp.fiscal_year
JOIN
dim_districts AS dis ON dis.dist_code = inves.dist_code
WHERE inves.fiscal_year IN (2021, 2022) GROUP BY dis.district;

11. Are there any particular sectors that have shown substantial investment in multiple districts between FY 2021 and 2022?

select count(distinct district) as count_dist, sector, round(sum(investment_in_cr),2) as inves_in_cr from fact_ts_ipass join dim_districts
on dim_districts.dist_code = fact_ts_ipass.dist_code where fiscal_year between 2021 and 2022 group by sector having count_dist > 1 
order by inves_in_cr desc;

12. Can we identify any seasonal patterns or cyclicality in the investment trends for specific sectors? Do certain sectors 
 experience higher investments during particular months?

SELECT sector, fiscal_year, MONTH(STR_TO_DATE(month, '%d/%m/%Y')) AS investment_month, round(SUM(investment_in_cr),2) AS Investment_in_cr 
FROM fact_ts_ipass WHERE fiscal_year >= 2021 AND fiscal_year <= 2022 GROUP BY investment_month, fiscal_year ORDER BY fiscal_year,
 investment_month;
