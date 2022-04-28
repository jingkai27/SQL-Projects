-- In this project, I imported a covid dataset from Our World In Data to do some simple analysis. 
-- Here are my code to obtain some of my findings.
USE covid_analysis;

-- 1. Looking at Total Cases vs Total Deaths in Singapore and United States
-- >> Skill: ORDER BY: can use column number as well. 
-- Shows likelihood of dying if you get Covid in Singapore/US
SELECT location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,2) AS death_percentage
FROM coviddeath_de
WHERE location = "Singapore"
ORDER BY 1;

SELECT location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,2) AS death_percentage
FROM coviddeath_de
WHERE location = "United States"
ORDER BY 1;

-- 2. Looking at Total Cases vs Population in Singapore and United States per day. 
-- >> Skill: Using ROUND() to round off values in columns to 2dp.
SELECT location, date, total_cases, population, round((total_cases/population)*100,2) AS population_percentage
FROM coviddeath_de
WHERE location = "Singapore"
ORDER BY date; 

SELECT location, date, total_cases, population, round((total_cases/population)*100,2) AS population_percentage
FROM coviddeath_de
WHERE location = "United States"
ORDER BY date; 

-- 3. Looking at Country with Highest Infection Rates
-- >> Using CAST() to convert to Integer. 
SELECT 
    location,
    population,
    MAX(CAST(total_cases AS UNSIGNED)) AS total_cases,
    ROUND((MAX(CAST(total_cases AS UNSIGNED)) / population) * 100,
            2) AS percentage_infected
FROM
    coviddeath_de
GROUP BY location, population
ORDER BY percentage_infected DESC;

-- 4. Show countries with Highest Death Percentage
-- > Skill: Using CONVERT() to convert to Integer
SELECT 
    location,
    MAX(total_cases) AS total_cases,
    MAX(CONVERT( total_deaths , UNSIGNED)) AS total_deaths,
    ROUND(MAX(CONVERT( total_deaths , UNSIGNED)) / MAX(total_cases) * 100,
            2) AS percentage_dead
FROM
    coviddeath_de
GROUP BY location
ORDER BY percentage_dead DESC;

-- 5. Show countries with Highest Death Count
-- >> Skill: Using NOT IN to state conditions, ORDER BY xxx DESC to obtain the highest at the top. 
SELECT 
    location,
    MAX(CAST(total_deaths AS UNSIGNED)) AS total_death_count
FROM
    coviddeath_de
WHERE
    location NOT IN ('High Income' , 'Europe',
        'North America',
        'South America',
        'European Union',
        'Low Income')
GROUP BY location
ORDER BY total_death_count DESC;

-- 6. Let's break things down by continent!
-- >> SKILL: Checking table information to ensure that column type is INT; if not, convert to integer (unsigned). 
SELECT 
    continent,
    MAX(total_cases) AS total_cases,
    MAX(CAST(total_deaths AS unsigned)) AS total_deaths,
    ROUND(MAX(CAST(total_deaths AS unsigned)) / MAX(total_cases) * 100,
            2) AS percentage_dead
FROM
    coviddeath_de
WHERE
    continent IS NOT NULL 
GROUP BY continent
ORDER BY percentage_dead DESC;

-- Finding numbers for Asia
-- >> SKILL: Using VIEWS to use an aggregate function on another aggregate function. 
DROP VIEW IF EXISTS asia_totalDeathCount;
CREATE VIEW asia_totalDeathCount AS
SELECT 
    location,
    SUM(CAST(new_deaths AS UNSIGNED)) AS totalDeathCount
FROM
    coviddeath_de
WHERE
    continent = "Asia"
GROUP BY location
ORDER BY totalDeathCount DESC;

SELECT 
    SUM(totalDeathCount) AS totalDeathCount
FROM
    asia_totalDeathCount; 

-- 7. Finding how many people died from Covid-19
SELECT * FROM coviddeath_de;
SELECT 
    SUM(new_cases) AS total_case,
    SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
    ROUND(SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases) * 100,
            2) AS death_percentage
FROM
    coviddeath_de;

-- 8. Looking at Total Population vs Vaccinated
SELECT * FROM coviddeath_de; 
SELECT * FROM covidvaccination_de; 

-- 8a. Finding percentage of population vaccinated per country
-- >> SKILL: Using JOIN to combine two charts. 
SELECT 
    v.location,
    d.population,
    MAX(CAST(v.people_fully_vaccinated AS UNSIGNED)) AS people_fully_vaccinated,
    ROUND((MAX(CAST(v.people_fully_vaccinated AS UNSIGNED)) / d.population) * 100,
            2) AS percentage_vaccinated
FROM
    coviddeath_de d
        JOIN
    covidvaccination_de v ON v.location = d.location
        AND v.date = d.date
GROUP BY v.location , d.population; 

-- 9. This chart shows the how many new vaccines are distributed daily 
-- >> Skill: Using PARTITION BY to sector by location so that we can get all records compared to GROUP BY. 
-- and the total number of vaccines distributed from the start to that particular day in question. 
SELECT 
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations, 
    SUM(CONVERT(v.new_vaccinations,UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS vaccines_distributed
FROM
    coviddeath_de d
        JOIN
    covidvaccination_de v ON v.location = d.location
        AND v.date = d.date;

-- 10. Finding the ratio of vaccines distributed to population 
-- >> Skill: Using an aggregate function on another aggregate function
-- Using Common Table Expressions
WITH PopVsVac(continent, location, date, population, newVaccinations, vaccinesDistributed)
AS
(SELECT 
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations, 
    SUM(CONVERT(v.new_vaccinations,UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS vaccines_distributed
FROM
    coviddeath_de d
        JOIN
    covidvaccination_de v ON v.location = d.location
        AND v.date = d.date)
        
SELECT *, round((vaccinesDistributed/population)*100, 2) as vaccine_to_pop FROM PopVsVac
;

-- Using Temp Table
DROP TABLE if exists vaccination_to_pop;
CREATE TABLE vaccination_to_pop
(
continent VARCHAR(255), 
location VARCHAR(255), 
date DATETIME, 
population INT, 
newVaccinations INT, 
vaccinesDistributed INT
);

INSERT INTO vaccination_to_pop
SELECT 
    d.continent,
    d.location,
    d.date,
    CONVERT(d.population, UNSIGNED),
    CONVERT(v.new_vaccinations, UNSIGNED),
    SUM(CONVERT(v.new_vaccinations,UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS vaccines_distributed
FROM
    coviddeath_de d
        JOIN
    covidvaccination_de v ON v.location = d.location
        AND v.date = d.date
        WHERE d.location = "Singapore";
	
-- CREATE VIEW 
DROP VIEW if exists vaccinationToPop;
CREATE VIEW vaccinationToPop AS 
SELECT 
    d.continent,
    d.location,
    d.date,
    CONVERT(d.population, UNSIGNED) AS population,
    CONVERT(v.new_vaccinations, UNSIGNED) AS new_vaccinations,
    SUM(CONVERT(v.new_vaccinations,UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS vaccines_distributed
FROM
    coviddeath_de d
        JOIN
    covidvaccination_de v ON v.location = d.location
        AND v.date = d.date
        WHERE d.location = "Singapore";

SELECT *, round((vaccines_distributed/population)*100, 2) as vaccine_to_pop
FROM vaccinationtopop;


