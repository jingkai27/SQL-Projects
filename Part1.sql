use covid_analysis;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths_2
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you get Covid in Singapore/US
SELECT location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,2) AS death_percentage
FROM coviddeaths_2
WHERE location = "Singapore"
ORDER BY 1;

SELECT location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,2) AS death_percentage
FROM coviddeaths_2
WHERE location = "United States"
ORDER BY 1;

-- Looking at Total Cases vs Population
-- What percentage of population got Covid
SELECT location, date, total_cases, population, round((total_cases/population)*100,2) AS population_percentage
FROM coviddeaths_2
WHERE location = "Singapore"
ORDER BY 1; 

SELECT location, date, total_cases, population, round((total_cases/population)*100,2) AS population_percentage
FROM coviddeaths_2
WHERE location = "United States"
ORDER BY 1; 

-- Looking at Country with Highest Infection Rates
SELECT location, total_cases, population, round((total_cases/population)*100,2) AS population_infected
FROM coviddeaths_2
WHERE date = "24/4/22"
ORDER BY population_infected DESC; 

SELECT location, population, MAX(total_cases) AS total_cases, round((MAX(total_cases)/population)*100, 2) AS percentage_infected
FROM coviddeaths_2
GROUP BY location, population
ORDER BY percentage_infected DESC;

-- Show countries with Highest Death Percentage
SELECT location, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths, round((MAX(total_deaths)/MAX(total_cases)*100), 2) AS percentage_dead
FROM coviddeaths_2
GROUP BY location
ORDER BY percentage_dead DESC;

-- Show countries with Highest Death Count
SELECT location, MAX(CAST(total_deaths AS unsigned)) AS total_death_count
from coviddeaths_2
GROUP BY location
ORDER BY total_death_count DESC;

-- Let's break things down by continent!
SELECT continent, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths, round((MAX(total_deaths)/MAX(total_cases)*100), 2) AS percentage_dead
FROM coviddeaths_2
WHERE continent IS NULL
GROUP BY continent
ORDER BY percentage_dead DESC;

-- Global Numbers
SELECT * FROM coviddeath_de;
SELECT SUM(new_cases) AS total_case, SUM(CAST(new_deaths AS unsigned)) as total_deaths, SUM(CAST(new_deaths AS unsigned))/SUM(new_cases)*100 as death_percentage
FROM coviddeath_de;

-- Looking at Total Population vs Vaccinated
SELECT * FROM coviddeath_de; 
SELECT * FROM covidvaccination_de; 

-- Finding percentage of population vaccinated per country
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

-- Increase in population taking vaccinations each day
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
        AND v.date = d.date
        WHERE d.location = "Singapore")
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


